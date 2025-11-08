// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C

public let abi: ABIProtocol = MockABI()
//public let abi: ABIProtocol = DefaultABI()

@_cdecl("psp_initialize")
public func _abi_initialize(
    eventContext: UnsafeMutableRawPointer?,
    eventCallback: psp_event_callback?
) {
    abi.initialize(eventContext: eventContext, eventCallback: eventCallback)
}

// MARK: - Global

@_cdecl("psp_json_new")
public func _abi_json_new(string: UnsafePointer<CChar>?) -> psp_json? {
    guard let string else { fatalError() }
    return UnsafePointer(strdup(string))
}

@_cdecl("psp_json_free")
public func _abi_json_free(json: psp_json?) {
    guard let json else { fatalError() }
    json.deallocate()
}

@_cdecl("psp_last_error")
public func _abi_last_error() -> psp_json? {
    nil
}

// MARK: - Profiles

@_cdecl("psp_profile_get_headers")
public func _abi_profile_get_headers() -> psp_json? {
    do {
        return try abi.profileGetHeaders().encoded()
    } catch {
        print(error.localizedDescription)
        return nil
    }
}

@_cdecl("psp_profile_new")
public func _abi_profile_new(completion: psp_completion?) {
    Task {
        do {
            let json = try await abi.profileNew().encoded()
            completion?(PSPErrorNone, json)
            psp_json_free(json)
        } catch {
            print(error.localizedDescription)
            completion?(PSPErrorSome, nil)
        }
    }
}

@_cdecl("psp_profile_import_text")
public func _abi_profile_import_text(text: UnsafePointer<CChar>?, completion: psp_completion?) {
    guard let text else { fatalError() }
    Task {
        do {
            let json = try await abi.profileImportText(String(cString: text)).encoded()
            completion?(PSPErrorNone, json)
            psp_json_free(json)
        } catch {
            print(error.localizedDescription)
            completion?(PSPErrorSome, nil)
        }
    }
}

@_cdecl("psp_profile_update")
public func _abi_profile_update(json: psp_json?, completion: psp_completion?) {
    guard let json else { fatalError() }
    Task {
        do {
            let json = try await abi.profileUpdate(String(cString: json)).encoded()
            completion?(PSPErrorNone, json)
            psp_json_free(json)
        } catch {
            print(error.localizedDescription)
            completion?(PSPErrorSome, nil)
        }
    }
}

@_cdecl("psp_profile_dup")
public func _abi_profile_dup(id: psp_id?, completion: psp_completion?) {
    guard let id else { fatalError() }
    Task {
        do {
            let json = try await abi.profileDup(String(cString: id)).encoded()
            completion?(PSPErrorNone, json)
            psp_json_free(json)
        } catch {
            print(error.localizedDescription)
            completion?(PSPErrorSome, nil)
        }
    }
}

@_cdecl("psp_profile_delete")
public func _abi_profile_delete(_ id: psp_id?, completion: psp_completion?) {
    guard let id else { fatalError() }
    Task {
        do {
            try await abi.profileDelete(String(cString: id))
            completion?(PSPErrorNone, nil)
        } catch {
            print(error.localizedDescription)
            completion?(PSPErrorSome, nil)
        }
    }
}

// MARK: - Tunnel

@_cdecl("psp_tunnel_get_all")
public func _abi_tunnel_get_all() -> psp_json? {
    do {
        return try abi.tunnelGetAll().encoded()
    } catch {
        print(error.localizedDescription)
        return nil
    }
}

@_cdecl("psp_tunnel_set_enabled")
public func _abi_tunnel_set_enabled(profileId: psp_id?, isEnabled: Bool) {
    guard let profileId else { fatalError() }
    abi.tunnelSetEnabled(isEnabled, profileId: String(cString: profileId))
}
