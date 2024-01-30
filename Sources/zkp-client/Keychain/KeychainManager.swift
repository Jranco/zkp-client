//
//  KeychainManager.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 22.01.24.
//

import Foundation
import BigInt

/// Executes CRUD operations in secure storage.
struct KeychainManager: KeychainManaging {
	
	// MARK: Private properties

	/// The unique user identifier used to distinguish storage context.
	private let userID: String
	
	// MARK: Initialization

	/// Creates an instance of a `KeychainManager` executing CRUD operation in secure storage.
	/// - Parameters:
	///   - userID: The unique user identifier used to distinguish storage context.
	init(userID: String) {
		self.userID = userID
	}

	// MARK: KeychainManaging

	func upsert(key: String, value: Data) throws {
		var query = Self.createQuery(for: key, userID: userID)
		let status = SecItemCopyMatching(query as CFDictionary, nil)
		switch status {
		case errSecSuccess:
			
			// Item exists, update
			let updatedQuery: [String: Any] = [
				kSecValueData as String: value
			]

			/// Update the item in the Keychain
			let updateStatus = SecItemUpdate(query as CFDictionary, updatedQuery as CFDictionary)

			if updateStatus != errSecSuccess {
				print("Error updating item in Keychain: \(updateStatus)")
			} else {
				print("Keychain item updated successfully")
			}
		case errSecItemNotFound:
			// Item doesn't exist, add a new item
			  let addQuery: [String: Any] = [
				  kSecClass as String: kSecClassGenericPassword,
				  kSecAttrService as String: key,
				  kSecValueData as String: value,
				  kSecAttrSynchronizable as String: kCFBooleanFalse!,
				  kSecAttrAccount as String: userID
			  ]
			
			query[kSecValueData as String] = value
			
			// Add the item to the Keychain
			let addStatus = SecItemAdd(query as CFDictionary, nil)

			if addStatus != errSecSuccess {
				print("Error adding item to Keychain: \(addStatus)")
			} else {
				print("Keychain item added successfully")
			}
		default:
			print("some default error: \(status)")
		}
	}
	
	func getValue(key: String) throws -> Data {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: key,
			kSecMatchLimit as String: kSecMatchLimitOne,
			kSecReturnAttributes as String: kCFBooleanTrue!,
			kSecReturnData as String: kCFBooleanTrue!,
			kSecAttrAccount as String: userID as CFString
		]

		var queryResult: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &queryResult)

		guard
			status == errSecSuccess,
			let resultDict = queryResult as? [String: Any]
		else {
			throw KeychainManagerError.didFailToRetrieveValueForKey
		}

		guard
			let data = resultDict[kSecValueData as String] as? Data
		else {
			throw KeychainManagerError.retrievedDataMalformed
		}

		return data
	}

	func remove(key: String, value: Data) throws {

	}
	
	func removeAllValues() throws {

	}
	
	// MARK: - Private methods

	private static func createQuery(for key: String, userID: String) -> [String: Any] {
		let query: [String: Any] = [
			 kSecClass as String: kSecClassGenericPassword,
			 kSecAttrService as String: key as CFString,
//			 kSecMatchLimit as String: kSecMatchLimitOne,
//			 kSecReturnAttributes as String: kCFBooleanTrue!,
//			 kSecReturnData as String: kCFBooleanTrue!,
			 kSecAttrSynchronizable as String: kCFBooleanFalse!,
			 kSecAttrAccount as String: userID as CFString
		 ]
		return query
	}
}

extension KeychainManager {
	enum KeychainManagerError: Error {
		case didFailToRetrieveValueForKey
		case retrievedDataMalformed
	}
}
