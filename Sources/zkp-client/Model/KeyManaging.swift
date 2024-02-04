//
//  KeyManaging.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 04.02.24.
//

import Foundation
import BigInt

/// A protocol defining requirements to generate keys based on user and device secrets.
protocol KeyManaging {
	associatedtype Key: Codable
	/// Generates public key based on the unique device identifier.
	func generateDevicePublicKey() throws -> Key
	/// Calculates and returns the `s` number that constitutes the private key.
	func fetchUniqueDeviceSecret() throws -> BigUInt
}
