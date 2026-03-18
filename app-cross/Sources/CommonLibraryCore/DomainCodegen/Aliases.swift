// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public typealias AppBundle = QuicktypeAppBundle
    public typealias AppConfiguration = QuicktypeAppConfiguration
    public typealias AppConstants = QuicktypeAppConstants
    public typealias AppFeature = QuicktypeAppFeature
    public typealias AppTunnelStatus = QuicktypeAppTunnelStatus
    public typealias AppUserLevel = QuicktypeAppUserLevel
    public typealias ConfigFlag = QuicktypeConfigFlag
    public typealias DistributionTarget = QuicktypeDistributionTarget
    public typealias ProfileSharingFlag = QuicktypeProfileSharingFlag
    public typealias SemanticVersion = QuicktypeSemanticVersion
    public typealias WebsiteWithPasscode = QuicktypeWebsiteWithPasscode
    public typealias WebFileUpload = QuicktypeWebFileUpload
}

extension ABI.AppConstants {
    public typealias Log = QuicktypeAppConstantsLog
    public typealias TunnelVerificationParameters = QuicktypeAppConstantsTunnelVerificationParameters
}

extension ABI.IAPEvent {
    public typealias Status = QuicktypeIAPEventStatus
    public typealias LoadReceipt = QuicktypeIAPEventLoadReceipt
    public typealias EligibleFeatures = QuicktypeIAPEventEligibleFeatures
}

extension ABI.ProfileEvent {
    public typealias Ready = QuicktypeProfileEventReady
    public typealias LocalProfiles = QuicktypeProfileEventLocalProfiles
    public typealias StartRemoteImport = QuicktypeProfileEventStartRemoteImport
    public typealias StopRemoteImport = QuicktypeProfileEventStopRemoteImport
    public typealias ChangeRemoteImporting = QuicktypeProfileEventChangeRemoteImporting
}

extension ABI.WebReceiverEvent {
    public typealias Start = QuicktypeWebReceiverEventStart
    public typealias Stop = QuicktypeWebReceiverEventStop
    public typealias NewUpload = QuicktypeWebReceiverEventNewUpload
    public typealias UploadFailure = QuicktypeWebReceiverEventUploadFailure
}
