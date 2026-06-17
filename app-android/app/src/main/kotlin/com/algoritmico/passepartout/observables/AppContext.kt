package com.algoritmico.passepartout.observables

import android.content.Context
import android.content.Intent
import android.util.Log
import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.business.extensions.throwIfCancellation
import com.algoritmico.passepartout.business.managers.ConfigManager
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.business.managers.VersionChecker
import com.algoritmico.passepartout.context.Tags
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
    val errorHandler: ErrorHandler
    val profileImporter: ProfileImporter
    val profileObservable: ProfileObservable
    val tunnelObservable: TunnelObservable
    val userPreferencesObservable: UserPreferencesObservable
    val versionObservable: VersionObservable

    init {
        Log.e(logTag, ">>> Started app")

        // User preferences
        userPreferencesObservable = UserPreferencesObservable(
            logTag,
            coroutineScope,
            applicationContext.userPreferencesStore
        )
        val preferences = userPreferencesObservable.currentPreferences
        Log.i(logTag, ">>> Preferences: $preferences")

        library.partoutInit(Tags.PARTOUT, preferences.logsPrivateData)
        val partoutVersion = library.partoutVersion()
        Log.i(logTag, ">>> Partout $partoutVersion")

        // Static app configuration
        val bundle = applicationContext.appBundle()
        Log.d(logTag, ">>> Bundle: $bundle")
        val constants = applicationContext.appConstants()
        Log.d(logTag, ">>> Constants: $bundle")
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
            requestVpnPermission
        )
        configManager = appConfiguration.newConfigManager(
            logTag,
            isBeta
        )
        profileManager = appConfiguration.newProfileManager(
            logTag,
            applicationContext,
            library
        )
        versionChecker = appConfiguration.newVersionChecker(
            logTag,
            userPreferencesObservable
        )

        // Observables from managers
        errorHandler = ErrorHandler
        configObservable = ConfigObservable(
            configManager,
            coroutineScope
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
            onImportSuccess = ::onApplicationActive
        )
        tunnelObservable = TunnelObservable(
            logTag,
            tunnel,
            profileManager,
            userPreferencesObservable.preferences,
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
                    runCatching {
                        if (!configManager.refreshBundle()) {
                            return@runCatching
                        }
                        val flags = configManager.activeFlags
                        persistConfigFlags(flags)
                    }.onFailure {
                        it.throwIfCancellation()
                        Log.e(logTag, "Unable to persist config flags", it)
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
    }

    private suspend fun persistConfigFlags(flags: Set<ConfigFlag>) {
        userPreferencesObservable.updatePreferences(
            fields = listOf(AppPreferenceKey.configFlags)
        ) {
            it.copy(configFlags = flags.toList())
        }
    }
}