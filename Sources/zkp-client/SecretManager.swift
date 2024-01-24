//
//  SecretManager.swift
//  znp-client
//
//  Created by Thomas Segkoulis on 17.01.24.
//

import Foundation
import UIKit
import BigInt
import CryptoKit

/// A protocol defining requirements to execute CRUD operations regarding user's and device's secrets.
protocol SecretManaging {
	/// Inserts a new secret safely in keychain or updates an existing one.
	/// - Parameters:
	///   - id: A unique identifier of the secret.
	///
	///	 	 - Note: This identifier is used to distinguish the secret within the local storage and
	///	 	 never leaves the device.
	///
	///   - userID: Unique user identifier.
	///   - buffer: The buffer accessing the bytes.
	///
	func upsertSecret<SecretID: Hashable>(
		with id: SecretID,
		userID: String,
		buffer: UnsafeRawBufferPointer?
	)

	/// Inserts a new secret safely in keychain or updates an existing one.
	/// - Parameters:
	///   - id: A unique identifier of the secret.
	///
	///	 	 - Note: This identifier is used to distinguish the secret within the local storage and
	///	 	 never leaves the device.
	///
	///   - userID: Unique user identifier.
	///   - intValue: The secret value represented as an integer number.
	///
	func upsertSecret<SecretID: Hashable>(
		with id: SecretID,
		userID: String,
		intValue: Int
	)

	/// Inserts a new secret safely in keychain or updates an existing one.
	/// - Parameters:
	///   - id: A unique identifier of the secret.
	///
	///	 	 - Note: This identifier is used to distinguish the secret within the local storage and
	///	 	 never leaves the device.
	///
	///   - userID: Unique user identifier.
	///   - intValue: The secret value represented as a string.
	///
	func upsertSecret<SecretID: Hashable>(
		with id: SecretID,
		userID: String,
		stringValue: String
	)

	/// Inserts a new secret safely in keychain or updates an existing one.
	/// - Parameters:
	///   - id: A unique identifier of the secret.
	///
	///	 	 - Note: This identifier is used to distinguish the secret within the local storage and
	///	 	 never leaves the device.
	///
	///   - userID: Unique user identifier.
	///   - intValue: The secret value represented as a generic type that is `Hashable`.
	///
	func upsertSecret<SecretID: Hashable, SecretValue: Hashable>(
		with id: SecretID,
		userID: String,
		value: SecretValue
	)
}


public class SecretManager: SecretManaging {

	/// An alphanumeric string that uniquely identifies a device to the app’s vendor.
	///
	/// - NOTE: If the value is nil, wait and get the value again later.
	/// This happens, for example, after the device has been restarted but before the user has unlocked the device.
	public static var deviceID: UUID? {
		return UIDevice.current.identifierForVendor
	}

	// MARK: - SecretManaging

	func upsertSecret<SecretID: Hashable>(
		with id: SecretID,
		userID: String,
		buffer: UnsafeRawBufferPointer?
	) {
		
	}
	
	func upsertSecret<SecretID: Hashable>(
		with id: SecretID,
		userID: String,
		intValue: Int
	) {
		// TODO:
	}
	
	func upsertSecret<SecretID: Hashable>(
		with id: SecretID,
		userID: String,
		stringValue: String
	) {
		// TODO:
	}
	
	func upsertSecret<SecretID: Hashable, SecretValue: Hashable>(
		with id: SecretID,
		userID: String,
		value: SecretValue
	) {
		// TODO:
	}
}
