// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public typealias AppBundle = OpenAPIAppBundle
    public typealias AppConfiguration = OpenAPIAppConfiguration
    public typealias AppConstants = OpenAPIAppConstants
    public typealias AppFeature = OpenAPIAppFeature
    public typealias AppTunnelStatus = OpenAPIAppTunnelStatus
    public typealias AppUserLevel = OpenAPIAppUserLevel
    public typealias ConfigFlag = OpenAPIConfigFlag
    public typealias Credits = OpenAPICredits
    public typealias DistributionTarget = OpenAPIDistributionTarget
    public typealias ProfileSharingFlag = OpenAPIProfileSharingFlag
    public typealias SemanticVersion = OpenAPISemanticVersion
    public typealias WebsiteWithPasscode = OpenAPIWebsiteWithPasscode
    public typealias WebFileUpload = OpenAPIWebFileUpload
}

extension ABI.AppConstants {
    public typealias Log = OpenAPIAppConstantsLog
    public typealias TunnelVerificationParameters = OpenAPIAppConstantsTunnelVerificationParameters
}

extension ABI.Credits {
    public typealias License = OpenAPICreditsLicensesInner
    public typealias Notice = OpenAPICreditsNoticesInner
}

extension ABI.IAPEvent {
    public typealias Status = OpenAPIIAPEventStatus
    public typealias LoadReceipt = OpenAPIIAPEventLoadReceipt
    public typealias EligibleFeatures = OpenAPIIAPEventEligibleFeatures
}

extension ABI.ProfileEvent {
    public typealias Ready = OpenAPIProfileEventReady
    public typealias LocalProfiles = OpenAPIProfileEventLocalProfiles
    public typealias StartRemoteImport = OpenAPIProfileEventStartRemoteImport
    public typealias StopRemoteImport = OpenAPIProfileEventStopRemoteImport
    public typealias ChangeRemoteImporting = OpenAPIProfileEventChangeRemoteImporting
}

extension ABI.WebReceiverEvent {
    public typealias Start = OpenAPIWebReceiverEventStart
    public typealias Stop = OpenAPIWebReceiverEventStop
    public typealias NewUpload = OpenAPIWebReceiverEventNewUpload
    public typealias UploadFailure = OpenAPIWebReceiverEventUploadFailure
}
