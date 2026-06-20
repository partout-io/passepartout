package com.algoritmico.passepartout.observables

import android.content.Context
import android.content.Intent
import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.managers.ConfigManager
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.business.managers.VersionChecker
import com.algoritmico.passepartout.context.AndroidConstants
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.defaultAndroidConstants
import com.algoritmico.passepartout.context.appBundle
import com.algoritmico.passepartout.context.appConstants
import com.algoritmico.passepartout.context.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.context.newConfigManager
import com.algoritmico.passepartout.context.newProfileManager
import com.algoritmico.passepartout.context.newTunnel
import com.algoritmico.passepartout.context.newVersionChecker
import com.algoritmico.passepartout.context.userPreferencesStore
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.ConfigFlag
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.supervisorScope
import java.io.Closeable

class AppContext(
    private val logTag: String,
    context: Context,
    private val coroutineScope: CoroutineScope,
    val androidConstants: AndroidConstants = defaultAndroidConstants,
    requestVpnPermission: (Intent) -> Unit
) : Closeable {
    private val applicationContext = context.applicationContext
    private val library = PassepartoutWrapper()

    // Internal logic
    private val configManager: ConfigManager
    private val profileManager: ProfileManager
    private val versionChecker: VersionChecker
    private var applicationActiveJob: Job? = null

    // Expose to Compose
    val appConfiguration: AppConfiguration
    val configObservable: ConfigObservable
    val diagnosticsObservable: DiagnosticsObservable
    val errorHandler: ErrorHandler
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
        val userPreferencesStore = applicationContext.userPreferencesStore(androidConstants.storage)
        userPreferencesObservable = UserPreferencesObservable(
            logTag,
            coroutineScope,
            userPreferencesStore
        )
        val preferences = userPreferencesObservable.currentPreferences
        AppLog.i(logTag, "Preferences: $preferences")
        library.partoutInit(androidConstants.logTags.appPartout, preferences.logsPrivateData)

        // Static app configuration
        val bundle = applicationContext.appBundle()
        AppLog.d(logTag, "Bundle: $bundle")
        val constants = applicationContext.appConstants(androidConstants.assets)
        AppLog.d(logTag, "Constants: $constants")
        appConfiguration = AppConfiguration(
            bundle = bundle,
            constants = constants
        )

        // Beta?
        val isBeta = context.isBetaSuggestedByAndroidAPI

        // Managers
        val tunnel = appConfiguration.newTunnel(
            logTag,
            applicationContext,
            androidConstants.tunnel,
            requestVpnPermission
        )
        configManager = appConfiguration.newConfigManager(
            logTag,
            isBeta,
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
        errorHandler = ErrorHandler(androidConstants.logTags.app)
        configObservable = ConfigObservable(
            configManager,
            coroutineScope
        )
        diagnosticsObservable = DiagnosticsObservable(
            logTags = androidConstants.logTags,
            diagnosticsConstants = androidConstants.diagnostics
        )
        profileObservable = ProfileObservable(
            profileManager,
            coroutineScope,
            errorHandler
        )
        profileImporter = ProfileImporter(
            logTag,
            applicationContext,
            coroutineScope,
            profileManager,
            androidConstants.profileImport,
            errorHandler,
            onImportSuccess = ::onApplicationActive
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

    fun onApplicationActive() {
        // FIXME: ###, AppContext, LifecycleManager.onApplicationActive()
//        library.appOnForeground()
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

    override fun close() {
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
