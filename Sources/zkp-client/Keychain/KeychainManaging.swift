//
//  KeychainManaging.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 22.01.24.
//

import Foundation

/// A protocol defining requirements to execute CRUD operations in secure storage.
protocol KeychainManaging {

	/// Inserts (if key doesn't exist) or updates the value in bytes for the given key in secure storage.
	/// - Parameters:
	///   - key: The key of the value to be stored. A prefix will be added locally to uniquely distinguished it from others, as keychain is accessible by other applications.
	///   - value: The data to be stored in bytes.
	func upsert(key: String, value: Data) throws

	func getValue(key: String) throws -> Data

	/// Removes the key and value from secure storage.
	/// - Parameters:
	///   - key: The key of the value to be stored. A prefix will be added locally to uniquely distinguished it from others, as keychain is accessible by other applications.
	///   - value: The data to be stored in bytes.
	func remove(key: String, value: Data) throws

	/// Removes all key and their respective values from secure storage
	func removeAllValues() throws
}
