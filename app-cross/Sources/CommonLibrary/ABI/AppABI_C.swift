// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

nonisolated(unsafe)
private var abi: AppABI?

@c(psp_app_init)
public func __psp_app_init(
    args: UnsafePointer<psp_app_init_args>?
) -> Int32 {
    guard let args else {
        return PSPCompletionCodeArgs
    }
    nonisolated(unsafe) var bindings = args.pointee.bindings
    guard let appBundleData = args.pointee.bundle?.asJSONData,
          let appConstantsData = args.pointee.constants?.asJSONData,
          let cProfilesDir = args.pointee.profiles_dir,
          let cCacheDir = args.pointee.cache_dir else {
        bindings.free?(&bindings)
        return PSPCompletionCodeArgs
    }
    let preferencesData = args.pointee.preferences?.asJSONData
    if args.pointee.preferences != nil {
        assert(preferencesData != nil, "Unable to decode preferences")
    }
    let profilesDir = String(cString: cProfilesDir)
    let cachesURL = URL(filePath: String(cString: cCacheDir))
    return ABI.runBlockingInitialization {
        do {
            abi = try AppABI.forCrossPlatform(
                bindings: bindings,
                appBundleData: appBundleData,
                appConstantsData: appConstantsData,
                preferencesData: preferencesData,
                profilesDir: profilesDir,
                cachesURL: cachesURL
            )
            return PSPCompletionCodeOK
        } catch {
            bindings.free?(&bindings)
            return PSPCompletionCodeFailure
        }
    }
}

@c(psp_app_deinit)
public func __psp_app_deinit(completion: psp_completion) {
    ABI.run(completion) { callback in
        abi?.unregisterEvents()
        abi = nil
        callback?(PSPCompletionCodeOK, nil)
    }
}

@c(psp_app_on_foreground)
public func __psp_app_on_foreground() {
    ABI.run {
        abi?.onApplicationActive()
    }
}

@c(psp_app_import_profile_path)
public func __psp_app_import_profile_path(
    path: UnsafePointer<CChar>?,
    completion: psp_completion
) {
    guard let abi, let path else {
        completion.callback?(completion.ctx, PSPCompletionCodeArgs, nil)
        return
    }
    let swiftPath = String(cString: path)
    ABI.run(completion) { callback in
        do {
            try await abi.profile.importFile(swiftPath, passphrase: nil)
            callback?(PSPCompletionCodeOK, nil)
        } catch {
            callback?(PSPCompletionCodeFailure, error.localizedDescription)
        }
    }
}

@c(psp_app_import_profile_text)
public func __psp_app_import_profile_text(
    text: UnsafePointer<CChar>?,
    filename: UnsafePointer<CChar>?,
    completion: psp_completion
) {
    guard let abi, let text, let filename else {
        completion.callback?(completion.ctx, PSPCompletionCodeArgs, nil)
        return
    }
    let swiftText = String(cString: text)
    let swiftFilename = String(cString: filename)
    ABI.run(completion) { callback in
        do {
            try await abi.profile.importText(swiftText, filename: swiftFilename, passphrase: nil)
            callback?(PSPCompletionCodeOK, nil)
        } catch {
            callback?(PSPCompletionCodeFailure, error.localizedDescription)
        }
    }
}

@c(psp_app_delete_profile)
public func __psp_app_delete_profile(
    uuid: UnsafePointer<CChar>?,
    completion: psp_completion
) {
    guard let abi, let uuid, let id = UUID(uuidString: String(cString: uuid)) else {
        completion.callback?(completion.ctx, PSPCompletionCodeArgs, nil)
        return
    }
    ABI.run(completion) { callback in
        await abi.profile.remove(id)
        callback?(PSPCompletionCodeOK, nil)
    }
}

@c(psp_app_delete_profiles)
public func __psp_app_delete_profiles(
    uuids: UnsafePointer<UnsafePointer<CChar>>?,
    num: Int,
    completion: psp_completion
) {
    guard let abi, let uuids else {
        completion.callback?(completion.ctx, PSPCompletionCodeArgs, nil)
        return
    }
    var ids: [Profile.ID] = []
    for cID in UnsafeBufferPointer(start: uuids, count: num) {
        guard let id = Profile.ID(uuidString: String(cString: cID)) else {
            continue
        }
        ids.append(id)
    }
    let fixedIds = ids
    ABI.run(completion) { callback in
        await abi.profile.remove(fixedIds)
        callback?(PSPCompletionCodeOK, nil)
    }
}

@c(psp_app_fetch_profile)
public func __psp_app_fetch_profile(
    uuid: UnsafePointer<CChar>?,
    completion: psp_completion
) {
    guard let abi, let uuid, let id = UUID(uuidString: String(cString: uuid)) else {
        completion.callback?(completion.ctx, PSPCompletionCodeArgs, nil)
        return
    }
    ABI.run(completion) { callback in
        guard let profile = abi.profile.profile(withId: id) else {
            callback?(PSPCompletionCodeFailure, "Profile not found")
            return
        }
        do {
            let data = try ABI.encode(profile.asTaggedProfile)
            let json = String(data: data, encoding: .utf8)
            callback?(PSPCompletionCodeOK, json)
        } catch {
            callback?(PSPCompletionCodeFailure, error.localizedDescription)
        }
    }
}

@c(psp_app_connect)
public func __psp_app_connect(
    profile: UnsafePointer<CChar>?,
    completion: psp_completion
) {
    guard let abi, let profile, let profileData = profile.asJSONData else {
        completion.callback?(completion.ctx, PSPCompletionCodeArgs, nil)
        return
    }
    let swiftProfile: Profile
    do {
        swiftProfile = try ABI.decode(TaggedProfile.self, from: profileData).asProfile()
    } catch {
        completion.callback?(completion.ctx, PSPCompletionCodeFailure, error.localizedDescription)
        return
    }
    ABI.run(completion) { callback in
        do {
            try await abi.tunnel.connect(to: swiftProfile, force: true)
            callback?(PSPCompletionCodeOK, nil)
        } catch {
            callback?(PSPCompletionCodeFailure, error.localizedDescription)
        }
    }
}

@c(psp_app_disconnect)
public func __psp_app_disconnect(
    uuid: UnsafePointer<CChar>?,
    completion: psp_completion
) {
    guard let abi, let uuid, let id = Profile.ID(uuidString: String(cString: uuid)) else {
        completion.callback?(completion.ctx, PSPCompletionCodeArgs, nil)
        return
    }
    ABI.run(completion) { callback in
        do {
            try await abi.tunnel.disconnect(from: id)
            callback?(PSPCompletionCodeOK, nil)
        } catch {
            callback?(PSPCompletionCodeFailure, error.localizedDescription)
        }
    }
}

@c(psp_app_flush_log)
public func __psp_app_flush_log() {
    pspLogFlush()
}

#endif
