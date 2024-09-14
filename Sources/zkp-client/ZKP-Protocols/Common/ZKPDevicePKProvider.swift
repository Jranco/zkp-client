//
//  ZKPDevicePKProvider.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 17.03.24.
//

import Foundation

protocol ZKPDevicePKProvider {
	/// Generates and returns a new public key based on the unique device identifier.
	func fetchDeviceKey() async throws -> Data
	/// Stores the device public key into secure storage.
	func storeNewDevicePublicKey(key: Data) throws
}
