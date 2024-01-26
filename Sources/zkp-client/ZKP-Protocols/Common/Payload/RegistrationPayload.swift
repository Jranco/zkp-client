//
//  RegistrationPayload.swift
//	zkp-client
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import Foundation

/// Payload to be sent during the registration step.
/// Contains the type of the zero-knowledge protocol to be used to prove the identity of the device along
/// with a custom payload from the initial request and a public key.
struct RegistrationPayload<Key: Codable>: Codable {
	/// The name of the `zero-knowledge` protocol.
	var protocolType: String
	/// The registration payload required by the target api.
	var payload: Data
	/// Unique user identifier.
	var userID: String
	/// The `zero-knowledge` public key.
	var key: Key
}
