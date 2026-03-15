package com.algoritmico.passepartout.abi

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import io.partout.abi.*

import kotlinx.serialization.json.JsonClassDiscriminator
import kotlinx.serialization.json.JsonElement

@Serializable
@JsonClassDiscriminator("eventType")
sealed class ABI_Event

@Serializable
@SerialName("ABI_ProviderInfo")
data class ABI_ProviderInfo(
    val providerId: ProviderID,
    val countryCode: String? = null,
)

@Serializable
@SerialName("ABI_AppProfileHeader")
data class ABI_AppProfileHeader(
    val id: String,
    val name: String,
    val moduleTypes: List<ModuleType>,
    val primaryModuleType: ModuleType? = null,
    val secondaryModuleTypes: List<ModuleType>? = null,
    val providerInfo: ABI_ProviderInfo? = null,
    val fingerprint: String,
    val sharingFlags: List<ABI_ProfileSharingFlag>,
    val requiredFeatures: Set<ABI_AppFeature>,
)

@Serializable
@SerialName("ABI_AppTunnelStatus")
enum class ABI_AppTunnelStatus {
    disconnected,
    connecting,
    connected,
    disconnecting,
}

@Serializable
@SerialName("ABI_AppTunnelInfo")
data class ABI_AppTunnelInfo(
    val id: String,
    val status: ABI_AppTunnelStatus,
    val onDemand: Boolean,
)

@Serializable
@SerialName("ABI_VersionRelease")
data class ABI_VersionRelease(
    val version: ABI_SemanticVersion,
    val url: String,
)

@Serializable
@SerialName("ABI_AppFeature")
enum class ABI_AppFeature {
    appleTV,
    dns,
    httpProxy,
    onDemand,
    otp,
    providers,
    routing,
    sharing,
}

@Serializable
@SerialName("ABI_OriginalPurchase")
data class ABI_OriginalPurchase(
    val buildNumber: Int,
    val purchaseDate: String,
)

@Serializable
@SerialName("ABI_WebsiteWithPasscode")
data class ABI_WebsiteWithPasscode(
    val url: String,
    val passcode: String? = null,
)

@Serializable
@SerialName("ABI_WebFileUpload")
data class ABI_WebFileUpload(
    val name: String,
    val contents: String,
)

@Serializable
@SerialName("ABI_ProfileSharingFlag")
enum class ABI_ProfileSharingFlag {
    shared,
    tv,
}

@Serializable
@SerialName("ABI_ConfigFlag")
enum class ABI_ConfigFlag {
    allowsRelaxedVerification,
    appNotWorking,
    neSocketUDP,
    neSocketTCP,
    unknown,
}

@Serializable
@SerialName("ABI_ConfigEvent_Refresh")
data class ABI_ConfigEvent_Refresh(
    val flags: Set<ABI_ConfigFlag>,
    val data: Map<ABI_ConfigFlag, JsonElement>,
) : ABI_Event()

@Serializable
@SerialName("ABI_IAPEvent_Status")
data class ABI_IAPEvent_Status(
    val isEnabled: Boolean,
) : ABI_Event()

@Serializable
@SerialName("ABI_IAPEvent_LoadReceipt")
data class ABI_IAPEvent_LoadReceipt(
    val isLoading: Boolean,
) : ABI_Event()

@Serializable
@SerialName("ABI_IAPEvent_NewReceipt")
data class ABI_IAPEvent_NewReceipt(
    val originalPurchase: ABI_OriginalPurchase? = null,
    val products: Set<ABI_AppProduct>,
    val isBeta: Boolean,
) : ABI_Event()

@Serializable
@SerialName("ABI_IAPEvent_EligibleFeatures")
data class ABI_IAPEvent_EligibleFeatures(
    val features: Set<ABI_AppFeature>,
    val forComplete: Boolean,
    val forFeedback: Boolean,
) : ABI_Event()

@Serializable
@SerialName("ABI_ProfileEvent_Ready")
class ABI_ProfileEvent_Ready(
) : ABI_Event()

@Serializable
@SerialName("ABI_ProfileEvent_LocalProfiles")
class ABI_ProfileEvent_LocalProfiles(
) : ABI_Event()

@Serializable
@SerialName("ABI_ProfileEvent_Refresh")
data class ABI_ProfileEvent_Refresh(
    val headers: Map<String, ABI_AppProfileHeader>,
) : ABI_Event()

@Serializable
@SerialName("ABI_ProfileEvent_Save")
class ABI_ProfileEvent_Save(
) : ABI_Event()

@Serializable
@SerialName("ABI_ProfileEvent_StartRemoteImport")
class ABI_ProfileEvent_StartRemoteImport(
) : ABI_Event()

@Serializable
@SerialName("ABI_ProfileEvent_StopRemoteImport")
class ABI_ProfileEvent_StopRemoteImport(
) : ABI_Event()

@Serializable
@SerialName("ABI_ProfileEvent_ChangeRemoteImporting")
data class ABI_ProfileEvent_ChangeRemoteImporting(
    val isImporting: Boolean,
) : ABI_Event()

@Serializable
@SerialName("ABI_TunnelEvent_Refresh")
data class ABI_TunnelEvent_Refresh(
    val active: Map<String, ABI_AppTunnelInfo>,
) : ABI_Event()

@Serializable
@SerialName("ABI_VersionEvent_New")
data class ABI_VersionEvent_New(
    val release: ABI_VersionRelease,
) : ABI_Event()

@Serializable
@SerialName("ABI_WebReceiverEvent_Start")
data class ABI_WebReceiverEvent_Start(
    val website: ABI_WebsiteWithPasscode,
) : ABI_Event()

@Serializable
@SerialName("ABI_WebReceiverEvent_Stop")
class ABI_WebReceiverEvent_Stop(
) : ABI_Event()

@Serializable
@SerialName("ABI_WebReceiverEvent_NewUpload")
data class ABI_WebReceiverEvent_NewUpload(
    val file: ABI_WebFileUpload,
) : ABI_Event()

@Serializable
@SerialName("ABI_WebReceiverEvent_UploadFailure")
data class ABI_WebReceiverEvent_UploadFailure(
    val error: String,
) : ABI_Event()

@Serializable
@SerialName("ABI_SemanticVersion")
data class ABI_SemanticVersion(
    val major: Int,
    val minor: Int,
    val patch: Int,
)

typealias ABI_AppProduct = String

typealias ProviderID = String

