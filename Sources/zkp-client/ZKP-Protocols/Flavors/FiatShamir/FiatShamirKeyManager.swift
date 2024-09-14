//
//  FiatShamirKeyManager.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 03.02.24.
//

import Foundation
import BigInt

/// An object managing and generating the private/public keys required by the FiatShamir identification protocol.
class FiatShamirKeyManager: KeyManaging {

	// MARK: - Public properties
	
	/// The number of bits of the `N` comprimes.
	/// - NOTE: An RSA minimum is from 1024 to 2048 bits.
	private(set) var coprimeWidth: Int

	// MARK: Private properties

	/// Executes CRUD operations regarding user's and device's secrets.
	private var secretManager: SecretManaging
	/// The unique user identifier.
	private let userID: String

	// MARK: - Initialization

	/// Creates an instance of an object managing and generating the private/public keys required by the FiatShamir identification protocol.
	/// - Parameters:
	///   - coprimeWidth: The number of bits of the `N` comprimes. An RSA minimum is from 1024 to 2048 bits.
	///   - secretManager: Executes CRUD operations regarding user's and device's secrets.
	///   - userID: The unique user identifier.
	public init(
		coprimeWidth: Int,
		secretManager: SecretManaging,
		userID: String
	) {
		self.coprimeWidth = coprimeWidth
		self.secretManager = secretManager
		self.userID = userID
	}

	// MARK: - KeyManaging

	func generateDevicePublicKey() async throws -> FiatShamir.PublicKey {
		let n = await generatePublicKeyN()
		let v = try generatePublicKeyV(n: n)
		return .init(vKey: v, nKey: n.serialize())
	}

	/// Calculates and returns the `s` number that constitutes the private key.
	func fetchUniqueDeviceSecret() throws -> BigUInt {
		/// At the moment use only the device's vendor identifier as main secret.
		// TODO: Use rest of secrets

		/// Check whether deviceID is available and throw error if not.
		/// If the value is nil, wait and get the value again later. This happens, for example, after the device has been restarted but before the user has unlocked the device.
		guard let deviceID = secretManager.deviceID else {
			throw FiatShamirError.unavailableDeviceID
		}
		/// Strips the `-` characters.
		let deviceIDStripped = deviceID.replacingOccurrences(of: "-", with: "")
		let secretEnhanced = addPadding(to: deviceIDStripped+userID.toHex(), totalBitsCount: coprimeWidth)

		/// Append the user identifier (converted into hex) to deviceID and convert into a big integer.
		guard let integerValue = BigUInt.init(secretEnhanced, radix: 16) ?? BigUInt(deviceIDStripped, radix: 10) else {
			throw FiatShamirError.couldNotConvertDeviceIDToInteger
		}
		return integerValue
	}
	
	private func addPadding(to secret: String, totalBitsCount: Int) -> String {
		guard let data = secret.data(using: .utf8) else {
			return secret
		}

		let numOfBits = data.count * 8
		
		guard numOfBits < totalBitsCount else {
//			if let truncatedData = data.firstNBits(totalBitsCount) {
//				return String(data: truncatedData, encoding: .utf8) ?? secret
//			}
			return secret
		}
		
		let numOfRepeats = totalBitsCount/numOfBits
		var concatenatedData = data
		
		for _ in 0..<numOfRepeats {
			concatenatedData.append(data)
		}
		
		let remaininDigits = (totalBitsCount % numOfBits)/8
		
		for _ in 0..<remaininDigits {
			concatenatedData.append("0".data(using: .utf8)!)
		}
		
		return String(data: concatenatedData, encoding: .utf8) ?? secret
	}

	// MARK: - Private methods

	/// Calculates and returns the `N` product of two big prime numbers (p x q) that constitutes the public key.
	@MainActor
	private func generatePublicKeyN() async -> BigUInt {
		let p = await generatePrime(coprimeWidth/2)
		let q = await generatePrime(coprimeWidth/2)
		return p.multiplied(by: q)
	}

	/// Generates a random prime number.
	/// - Parameter width: The number of uniformly distributed random bits representing a prime number.
	/// - Returns a big integer.
	private func generatePrime(_ width: Int) async -> BigUInt {
		while true {
			var random = BigUInt.randomInteger(withExactWidth: width + 1)
			random |= BigUInt(1)
			if random.isPrime() {
				return random
			}
		}
	}

	/// Calculates and returns the protocol's `v` public key that uses the user and device secrets along with the `N` product of prime numbers.
	/// Returns the big integer key in a `Data` value that contains the base-256 representation of this integer, in network (big-endian) byte order.
	func generatePublicKeyV(n: BigUInt) throws -> Data {
		/// Get the `s` secret number based on the unique device identifier (`VendorID`).
		let s = try fetchUniqueDeviceSecret()
		/// Calculate the public `v` key.
		let v = s.power(2, modulus: n)
		return v.serialize()
	}
}
