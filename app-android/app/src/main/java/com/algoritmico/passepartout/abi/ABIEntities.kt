// To parse the JSON, install kotlin's serialization plugin and do:
//
// val json                              = Json { allowStructuredMapKeys = true }
// val appBundle                         = json.parse(AppBundle.serializer(), jsonString)
// val appConfiguration                  = json.parse(AppConfiguration.serializer(), jsonString)
// val appConstants                      = json.parse(AppConstants.serializer(), jsonString)
// val appFeature                        = json.parse(AppFeature.serializer(), jsonString)
// val appProfileHeader                  = json.parse(AppProfileHeader.serializer(), jsonString)
// val appTunnelInfo                     = json.parse(AppTunnelInfo.serializer(), jsonString)
// val appTunnelStatus                   = json.parse(AppTunnelStatus.serializer(), jsonString)
// val appUserLevel                      = json.parse(AppUserLevel.serializer(), jsonString)
// val configEventRefresh                = json.parse(ConfigEventRefresh.serializer(), jsonString)
// val configFlag                        = json.parse(ConfigFlag.serializer(), jsonString)
// val credits                           = json.parse(Credits.serializer(), jsonString)
// val distributionTarget                = json.parse(DistributionTarget.serializer(), jsonString)
// val iAPEventEligibleFeatures          = json.parse(IAPEventEligibleFeatures.serializer(), jsonString)
// val iAPEventLoadReceipt               = json.parse(IAPEventLoadReceipt.serializer(), jsonString)
// val iAPEventNewReceipt                = json.parse(IAPEventNewReceipt.serializer(), jsonString)
// val iAPEventStatus                    = json.parse(IAPEventStatus.serializer(), jsonString)
// val originalPurchase                  = json.parse(OriginalPurchase.serializer(), jsonString)
// val profileEventChangeRemoteImporting = json.parse(ProfileEventChangeRemoteImporting.serializer(), jsonString)
// val profileEventLocalProfiles         = json.parse(ProfileEventLocalProfiles.serializer(), jsonString)
// val profileEventReady                 = json.parse(ProfileEventReady.serializer(), jsonString)
// val profileEventRefresh               = json.parse(ProfileEventRefresh.serializer(), jsonString)
// val profileEventSave                  = json.parse(ProfileEventSave.serializer(), jsonString)
// val profileEventStartRemoteImport     = json.parse(ProfileEventStartRemoteImport.serializer(), jsonString)
// val profileEventStopRemoteImport      = json.parse(ProfileEventStopRemoteImport.serializer(), jsonString)
// val profileSharingFlag                = json.parse(ProfileSharingFlag.serializer(), jsonString)
// val providerInfo                      = json.parse(ProviderInfo.serializer(), jsonString)
// val semanticVersion                   = json.parse(SemanticVersion.serializer(), jsonString)
// val timestamp                         = json.parse(Timestamp.serializer(), jsonString)
// val tunnelEventDataCount              = json.parse(TunnelEventDataCount.serializer(), jsonString)
// val tunnelEventRefresh                = json.parse(TunnelEventRefresh.serializer(), jsonString)
// val versionEventNew                   = json.parse(VersionEventNew.serializer(), jsonString)
// val versionRelease                    = json.parse(VersionRelease.serializer(), jsonString)
// val webFileUpload                     = json.parse(WebFileUpload.serializer(), jsonString)
// val webReceiverEventNewUpload         = json.parse(WebReceiverEventNewUpload.serializer(), jsonString)
// val webReceiverEventStart             = json.parse(WebReceiverEventStart.serializer(), jsonString)
// val webReceiverEventStop              = json.parse(WebReceiverEventStop.serializer(), jsonString)
// val webReceiverEventUploadFailure     = json.parse(WebReceiverEventUploadFailure.serializer(), jsonString)
// val websiteWithPasscode               = json.parse(WebsiteWithPasscode.serializer(), jsonString)

package com.algoritmico.passepartout.abi

import kotlinx.serialization.*
import kotlinx.serialization.json.*
import kotlinx.serialization.descriptors.*
import kotlinx.serialization.encoding.*

typealias Timestamp = String

@Serializable
data class AppConfiguration (
    val bundle: AppBundle,
    val constants: AppConstants
)

@Serializable
data class AppBundle (
    val appLogPath: String,
    val appLogsURL: String,
    val buildNumber: Long,
    val bundleStrings: Map<String, String>,
    val customUserLevel: AppUserLevel? = null,
    val displayName: String,
    val distributionTarget: DistributionTarget,
    val reviewURL: String? = null,
    val tunnelLogPath: String,
    val tunnelLogsURL: String,
    val versionNumber: String
)

@Serializable
enum class AppUserLevel(val value: String) {
    @SerialName("beta") Beta("beta"),
    @SerialName("complete") Complete("complete"),
    @SerialName("essentials") Essentials("essentials"),
    @SerialName("freemium") Freemium("freemium"),
    @SerialName("undefined") Undefined("undefined");
}

@Serializable
enum class DistributionTarget(val value: String) {
    @SerialName("appStore") AppStore("appStore"),
    @SerialName("developerID") DeveloperID("developerID"),
    @SerialName("enterprise") Enterprise("enterprise");
}

@Serializable
data class AppConstants (
    val api: AppConstantsAPI,
    val containers: AppConstantsContainers,

    @SerialName("deviceIdLength")
    val deviceIDLength: Long,

    val emails: AppConstantsEmails,
    val formats: AppConstantsFormats,
    val github: AppConstantsGitHub,
    val iap: AppConstantsIAP,
    val log: AppConstantsLog,
    val tunnel: AppConstantsTunnel,
    val webReceiver: AppConstantsWebReceiver,
    val websites: AppConstantsWebsites
)

@Serializable
data class AppConstantsAPI (
    val refreshInfrastructureRateLimit: Double,
    val timeoutInterval: Double,
    val versionRateLimit: Double
)

@Serializable
data class AppConstantsContainers (
    val backup: String,
    val local: String,
    val remote: String
)

@Serializable
data class AppConstantsEmails (
    val domain: String,
    val recipients: AppConstantsEmailsRecipients
)

@Serializable
data class AppConstantsEmailsRecipients (
    val beta: String,
    val issues: String
)

@Serializable
data class AppConstantsFormats (
    val timestamp: String
)

@Serializable
data class AppConstantsGitHub (
    val discussionsURL: String,
    val issuesURL: String,
    val latestReleaseURL: String,
    val rawURL: String
)

@Serializable
data class AppConstantsIAP (
    val productsTimeoutInterval: Double,
    val receiptInvalidationInterval: Double
)

@Serializable
data class AppConstantsLog (
    val formatter: AppConstantsLogFormatter,
    val options: AppConstantsLogOptions,
    val sinceLast: Double
)

@Serializable
data class AppConstantsLogFormatter (
    val message: String,
    val timestamp: String
)

@Serializable
data class AppConstantsLogOptions (
    /**
     * Optional maximum age in seconds
     */
    val maxAge: Double? = null,

    val maxBufferedLines: Long,

    /**
     * DebugLog.Level (0=debug, 1=info, 2=warning, 3=error)
     */
    val maxLevel: Long,

    /**
     * Maximum size in bytes
     */
    val maxSize: Long
)

@Serializable
data class AppConstantsTunnel (
    val dnsFallbackServers: List<String>,
    val profileTitleFormat: String,
    val refreshInterval: Double,
    val verification: AppConstantsTunnelVerification
)

@Serializable
data class AppConstantsTunnelVerification (
    val beta: AppConstantsTunnelVerificationParameters,
    val production: AppConstantsTunnelVerificationParameters
)

@Serializable
data class AppConstantsTunnelVerificationParameters (
    val attempts: Long,
    val delay: Double,
    val interval: Double,
    val retryInterval: Double
)

@Serializable
data class AppConstantsWebReceiver (
    val passcodeLength: Long,
    val port: Long
)

@Serializable
data class AppConstantsWebsites (
    val appStoreDownloadURL: String,
    val configTTL: Double,
    val eulaURL: String,
    val homeURL: String,
    val macDownloadURL: String,
    val subredditURL: String
)

@Serializable
data class ConfigEventRefresh (
    val data: JsonObject,
    val flags: List<ConfigFlag>
) : ABIEvent()

@Serializable
enum class ConfigFlag(val value: String) {
    @SerialName("allowsRelaxedVerification") AllowsRelaxedVerification("allowsRelaxedVerification"),
    @SerialName("appNotWorking") AppNotWorking("appNotWorking"),
    @SerialName("neSocketTCP") NeSocketTCP("neSocketTCP"),
    @SerialName("neSocketUDP") NeSocketUDP("neSocketUDP"),
    @SerialName("unknown") Unknown("unknown");
}

@Serializable
data class Credits (
    val licenses: List<License>,
    val notices: List<Notice>,
    val translations: Map<String, List<String>>
)

@Serializable
data class License (
    val licenseName: String,
    val licenseURL: String,
    val name: String
)

@Serializable
data class Notice (
    val message: String,
    val name: String
)

@Serializable
data class IAPEventEligibleFeatures (
    val features: List<AppFeature>,
    val forComplete: Boolean,
    val forFeedback: Boolean
) : ABIEvent()

@Serializable
enum class AppFeature(val value: String) {
    @SerialName("appleTV") AppleTV("appleTV"),
    @SerialName("dns") DNS("dns"),
    @SerialName("httpProxy") HTTPProxy("httpProxy"),
    @SerialName("onDemand") OnDemand("onDemand"),
    @SerialName("otp") Otp("otp"),
    @SerialName("providers") Providers("providers"),
    @SerialName("routing") Routing("routing"),
    @SerialName("sharing") Sharing("sharing");
}

@Serializable
data class IAPEventLoadReceipt (
    val isLoading: Boolean
) : ABIEvent()

@Serializable
data class IAPEventNewReceipt (
    val isBeta: Boolean,
    val originalPurchase: OriginalPurchase? = null,
    val products: List<String>
) : ABIEvent()

@Serializable
data class OriginalPurchase (
    val buildNumber: Long,
    val purchaseDate: String
)

@Serializable
data class IAPEventStatus (
    val isEnabled: Boolean
) : ABIEvent()

@Serializable
data class ProfileEventChangeRemoteImporting (
    val isImporting: Boolean
) : ABIEvent()

@Serializable
class ProfileEventLocalProfiles(): ABIEvent()

@Serializable
class ProfileEventReady(): ABIEvent()

@Serializable
data class ProfileEventRefresh (
    val headers: Map<String, AppProfileHeader>
) : ABIEvent()

@Serializable
data class AppProfileHeader (
    val fingerprint: String,
    val id: String,
    val moduleTypes: List<ModuleType>,
    val name: String,
    val primaryModuleType: ModuleType? = null,
    val providerInfo: ProviderInfo? = null,
    val requiredFeatures: List<AppFeature>,
    val secondaryModuleTypes: List<ModuleType>,
    val sharingFlags: List<ProfileSharingFlag>
)

@Serializable
enum class ModuleType(val value: String) {
    @SerialName("DNS") DNS("DNS"),
    @SerialName("HTTPProxy") HTTPProxy("HTTPProxy"),
    @SerialName("IP") IP("IP"),
    @SerialName("OnDemand") OnDemand("OnDemand"),
    @SerialName("OpenVPN") OpenVPN("OpenVPN"),
    @SerialName("WireGuard") WireGuard("WireGuard");
}

@Serializable
data class ProviderInfo (
    val countryCode: String? = null,

    @SerialName("providerId")
    val providerID: String
)

@Serializable
enum class ProfileSharingFlag(val value: String) {
    @SerialName("shared") Shared("shared"),
    @SerialName("tv") Tv("tv");
}

@Serializable
class ProfileEventSave(): ABIEvent()

@Serializable
class ProfileEventStartRemoteImport(): ABIEvent()

@Serializable
class ProfileEventStopRemoteImport(): ABIEvent()

@Serializable
class TunnelEventDataCount(): ABIEvent()

@Serializable
data class TunnelEventRefresh (
    val active: Map<String, AppTunnelInfo>
) : ABIEvent()

@Serializable
data class AppTunnelInfo (
    val id: String,
    val onDemand: Boolean,
    val status: AppTunnelStatus
)

@Serializable
enum class AppTunnelStatus(val value: String) {
    @SerialName("connected") Connected("connected"),
    @SerialName("connecting") Connecting("connecting"),
    @SerialName("disconnected") Disconnected("disconnected"),
    @SerialName("disconnecting") Disconnecting("disconnecting");
}

@Serializable
data class VersionEventNew (
    val release: VersionRelease
) : ABIEvent()

@Serializable
data class VersionRelease (
    val url: String,
    val version: SemanticVersion
)

@Serializable
data class SemanticVersion (
    val major: Long,
    val minor: Long,
    val patch: Long
)

@Serializable
data class WebReceiverEventNewUpload (
    val file: WebFileUpload
) : ABIEvent()

@Serializable
data class WebFileUpload (
    val contents: String,
    val name: String
)

@Serializable
data class WebReceiverEventStart (
    val website: WebsiteWithPasscode
) : ABIEvent()

@Serializable
data class WebsiteWithPasscode (
    val passcode: String? = null,
    val url: String
)

@Serializable
class WebReceiverEventStop(): ABIEvent()

@Serializable
data class WebReceiverEventUploadFailure (
    val error: String
) : ABIEvent()
@Serializable sealed class ABIEvent
