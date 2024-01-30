//
//  AuthenticationPayload.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

/// Payload to be sent during the authentication step.
/// Contains the type of the zero-knowledge protocol to be used to prove the identity of the device along
/// with a custom payload from the initial authentication request and a public key.
///
/// - NOTE: Payload could contain `OTP`content or `SCA` or whatever is used to authenticate a client.
///
struct AuthenticationPayload<Key: Codable>: Codable {
	/// The name of the `zero-knowledge` protocol.
	var protocolType: String
	/// The registration payload required by the target api.
	var payload: Data
	/// Unique user identifier.
	var userID: String
	/// The `zero-knowledge` public key.
	///
	/// - NOTE: It is used to be able to identify the device. User might have multiple `binded` devices.
	var key: Key
	
	var initiatingNum: Data
	var challengeResponse: Data
}
