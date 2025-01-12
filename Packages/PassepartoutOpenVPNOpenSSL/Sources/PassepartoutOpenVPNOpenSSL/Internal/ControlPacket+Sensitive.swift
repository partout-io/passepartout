//
//  ControlPacket+Sensitive.swift
//  PassepartoutKit
//
//  Created by Davide De Rosa on 5/2/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of PassepartoutKit.
//
//  PassepartoutKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  PassepartoutKit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with PassepartoutKit.  If not, see <http://www.gnu.org/licenses/>.
//

internal import CPassepartoutOpenVPNOpenSSL
import Foundation
import PassepartoutKit

extension ControlPacket: @retroactive SensitiveDebugStringConvertible {
    func debugDescription(withSensitiveData: Bool) -> String {
        var msg: [String] = ["\(code) | \(key)"]
        msg.append("sid: \(sessionId.toHex())")
        if let ackIds = ackIds, let ackRemoteSessionId = ackRemoteSessionId {
            msg.append("acks: {\(ackIds), \(ackRemoteSessionId.toHex())}")
        }
        if !isAck {
            msg.append("pid: \(packetId)")
        }
        if let payload {
            msg.append(payload.asSensitiveBytes)
        }
        return "{\(msg.joined(separator: ", "))}"
    }
}
