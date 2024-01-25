//
//  FiatShamir.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 24.01.24.
//

import Foundation
import BigInt

/// The basic `Fiat-Shamir` zero-knowledge identification protocol implementation.
public struct FiatShamir: ZeroKnowledgeProtocol {

	// MARK: Secret manager

	private(set) var secretManager: SecretManaging

	// MARK: - Private properties

	/// Configuration parameters required by the protocol (i.e. `N` coprime bit length).
	private let configuration: Config

	// MARK: - Initialization

	/// Creates an instace of a the basic `Fiat-Shamir` zero-knowledge identification protocol implementation.
	/// - Parameters:
	///   - secretManager: An object executing CRUD operations regarding user's and device's secrets.
	///   - configuration: Configuration parameters required by the protocol (i.e. `N` coprime bit length).
	init(
		secretManager: SecretManaging,
		configuration: Config
	) {
		self.secretManager = secretManager
		self.configuration = configuration
	}

	// MARK: - ZeroKnowledgeProtocol
	
	func calculatePublicKey() throws -> PublicKey {
		let n = calculateN()
		let v = try calculateV()
		print("N == \(n)")
		return .init(v: v, n: n.serialize())
	}

	func register() {
	}
	
	func initiateIdentification() {
	}
}

// MARK: - Public methods

public extension FiatShamir {
	/// Config parameters required by the protocol.
	struct Config {
		/// The number of bits of the `N` comprimes.
		/// - NOTE: An RSA minimum is from 1024 to 2048 bits.
		var coprimeWidth: Int
	}
	/// Error cases thrown by the protocol.
	enum FiatShamirError: LocalizedError {
		case unavailableDeviceID
		case couldNotConvertDeviceIDToInteger
		public var errorDescription: String? {
			switch self {
			case .unavailableDeviceID:
				return "The unique device identifier cannot be retrieved at the moment, please try again later. This happens, for example, after the device has been restarted but before the user has unlocked the device"
			case .couldNotConvertDeviceIDToInteger:
				return "Device identifier is not in a format that can be transformed into an integer number"
			}
		}
	}
}

// MARK: - Public methods

public extension FiatShamir {
	/// The public key.
	/// Contains the `N` and `v` sub-keys.
	struct PublicKey {
		var v: Data
		var n: Data
	}
}

// MARK: - Private methods

private extension FiatShamir {
	/// Calculates and returns the `N` (p x q) number that constitutes the public key.
	func calculateN() -> BigUInt {
		let p = BigUInt.randomInteger(withExactWidth: configuration.coprimeWidth)
		let q = BigUInt.randomInteger(withExactWidth: configuration.coprimeWidth)
		return p.multiplied(by: q)
	}

	/// Calculates and returns the `s` number that constitutes the private key.
	func calculateSecret() throws -> BigUInt {
		/// At the moment use only the device's vendor identifier as main secret.
		// TODO: Use rest of secrets

		/// Check whether deviceID is available and throw error if not.
		/// If the value is nil, wait and get the value again later. This happens, for example, after the device has been restarted but before the user has unlocked the device.
		guard let deviceID = secretManager.deviceID else {
			throw FiatShamirError.unavailableDeviceID
		}

		/// Convert the hexadecimal string into integer.
		/// If that fails, meaning it's not a hexadecimal, then try with the default base 10.
		guard let integerValue = UInt64(deviceID, radix: 16) ?? UInt64(deviceID) else {
			throw FiatShamirError.couldNotConvertDeviceIDToInteger
		}

		return BigUInt(integerLiteral: integerValue)
	}

	/// Calculates and returns the protocol's `v` public key.
	/// Returns the big integer key in a `Data` value that contains the base-256 representation of this integer, in network (big-endian) byte order.
	func calculateV() throws -> Data {
		/// Calculate the `N` number.
		let n = calculateN()
		/// Calculate the `s` secret number.
		let s = try calculateSecret()
		/// Calculate the public `v` key.
		let v = s.power(2, modulus: n)
		print("V == \(v)")
		return v.serialize()
	}
}
