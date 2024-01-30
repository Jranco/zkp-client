//
//  KeychainManager+Extensions.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

extension KeychainManager {
	/// Upserts `FiatShamir` private keys.
	func upsert(key: FiatShamirKeyName, value: Data) throws {
		try upsert(key: key.rawValue, value: value)
	}
	/// Fetch value given a `FiatShamir` private key.
	func getValue(key: FiatShamirKeyName) throws -> Data {
		try getValue(key: key.rawValue)
	}
}
