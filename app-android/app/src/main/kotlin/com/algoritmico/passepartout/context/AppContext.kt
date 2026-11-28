package com.algoritmico.passepartout.context

import android.content.Context
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.managers.ConfigManager
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.business.managers.VersionChecker
import com.algoritmico.passepartout.business.models.decodedPairs
import com.algoritmico.passepartout.business.strategy.PartoutWireGuardKeyGenerator
import com.algoritmico.passepartout.business.strategy.WireGuardKeyGenerator
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.observables.ConfigObservable
import com.algoritmico.passepartout.observables.DiagnosticsObservable
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.ProfileImporter
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.observables.VersionObservable
import com.algoritmico.passepartout.observables.VpnPermissionObservable
import java.io.Closeable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.supervisorScope

class AppContext(
    private val logTag: String,
    context: Context,
    private val coroutineScope: CoroutineScope,
    val androidConstants: AndroidConstants = defaultAndroidConstants
) : Closeable {
    private val applicationContext = context.applicationContext
    private val library = androidConstants.newWrapper()

    // Internal logic
    private val configManager: ConfigManager
    private val profileManager: ProfileManager
    private val versionChecker: VersionChecker
    private var applicationActiveJob: Job? = null

    val wireGuardKeyGenerator: WireGuardKeyGenerator = PartoutWireGuardKeyGenerator(library)

    // Expose to Compose
    val appConfiguration: AppConfiguration
    val configObservable: ConfigObservable
    val diagnosticsObservable: DiagnosticsObservable
    val errorHandler: ErrorHandler
    val vpnPermissionObservable = VpnPermissionObservable()
    val profileImporter: ProfileImporter
    val profileObservable: ProfileObservable
    val tunnelObservable: TunnelObservable
    val userPreferencesObservable: UserPreferencesObservable
    val versionObservable: VersionObservable

    init {
        AppLog.i(logTag, "Started app")
        val partoutVersion = library.partoutVersion()
        AppLog.i(logTag, "Partout $partoutVersion")

        // User preferences
        val userPreferencesStore = applicationContext.userPreferencesStore
        userPreferencesObservable = UserPreferencesObservable(
            logTag,
            coroutineScope,
            userPreferencesStore
        )
        val preferences = userPreferencesObservable.currentPreferences
        AppLog.i(logTag, "Preferences: $preferences")
        library.partoutInit(androidConstants.tags.partoutApp, preferences.logsPrivateData)

        // Static app configuration
        val bundle = applicationContext.appBundle()
        AppLog.d(logTag, "Bundle: $bundle")
        val constants = applicationContext.appConstants(androidConstants.assets)
        AppLog.d(logTag, "Constants: $constants")
        appConfiguration = AppConfiguration(
            bundle = bundle,
            constants = constants
        )

        // Managers
        val tunnel = appConfiguration.newTunnel(
            logTag,
            applicationContext,
            androidConstants.tunnel,
            vpnPermissionObservable::request
        )
        configManager = appConfiguration.newConfigManager(
            logTag,
            androidConstants.events
        )
        profileManager = appConfiguration.newProfileManager(
            logTag,
            applicationContext,
            library,
            androidConstants.events
        )
        versionChecker = appConfiguration.newVersionChecker(
            logTag,
            userPreferencesStore,
            coroutineScope,
            androidConstants.events
        )

        // Observables from managers
        errorHandler = ErrorHandler(androidConstants.tags.app)
        configObservable = ConfigObservable(
            configManager,
            coroutineScope
        )
        diagnosticsObservable = DiagnosticsObservable(
            tags = androidConstants.tags,
            diagnosticsConstants = androidConstants.diagnostics
        )
        profileObservable = ProfileObservable(
            profileManager,
            coroutineScope,
            errorHandler,
            canRemoveProfiles = { ids ->
                val state = tunnel.state.value
                state.policy.alwaysOn != true ||
                    (state.snapshots.isNotEmpty() && ids.none { it in state.snapshots })
            }
        )
        profileImporter = ProfileImporter(
            coroutineScope = coroutineScope,
            readProfiles = { input ->
                input.decodedPairs(
                    applicationContext.contentResolver,
                    applicationContext.getString(R.string.placeholders_profile_imported_name),
                    logTag
                )
            },
            importText = profileManager::importText,
            reportError = errorHandler::report,
            onImportSuccess = ::onApplicationActive,
            logTag = logTag
        )
        tunnelObservable = TunnelObservable(
            logTag,
            tunnel,
            profileManager,
            userPreferencesStore.data,
            coroutineScope
        )
        versionObservable = VersionObservable(
            versionChecker,
            coroutineScope
        )
    }

    fun onVpnPermissionResult(isGranted: Boolean) {
        if (vpnPermissionObservable.complete()) {
            tunnelObservable.onVpnPermissionResult(isGranted)
        }
    }

    fun onApplicationActive() {
        tunnelObservable.refresh()
        if (applicationActiveJob?.isActive == true) {
            return
        }
        applicationActiveJob = coroutineScope.launch {
            supervisorScope {
                launch {
                    runCatchingNonFatal {
                        if (!configManager.refreshBundle()) {
                            return@runCatchingNonFatal
                        }
                        val flags = configManager.activeFlags
                        persistConfigFlags(flags)
                    }.onFailure {
                        AppLog.w(logTag, "Unable to update config flags", it)
                        configManager.resetTTL()
                    }
                }
                launch {
                    versionChecker.checkLatestRelease()
                }
            }
        }
    }

//    fun onSaveProfile() {
//        // Observe ProfileManager events
//        // Reconnect on relevant changes (old/new profile diff)
//    }

    override fun close() {
        profileImporter.close()
        configObservable.close()
        profileObservable.close()
        tunnelObservable.close()
        userPreferencesObservable.close()
        versionObservable.close()
        versionChecker.close()
    }

    private suspend fun persistConfigFlags(flags: Set<ConfigFlag>) {
        userPreferencesObservable.updatePreferences(
            fields = listOf(AppPreferenceKey.configFlags)
        ) {
            it.copy(configFlags = flags.toList())
        }
    }
}
