////
////  FiatShamirKeyManager.swift
////  zkp=client
////
////  Created by Thomas Segkoulis on 03.02.24.
////
//
//import Foundation
//import BigInt
//
//class FiatShamirKeyManager {
//	/// Calculates and returns the `N` product of two big prime numbers (p x q) that constitutes the public key.
//	func generatePublicKeyN() -> BigUInt {
//		let p = generatePrime(configuration.coprimeWidth)
//		let q = generatePrime(configuration.coprimeWidth)
//		return p.multiplied(by: q)
//	}
//
//	/// Generates a random prime number.
//	/// - Parameter width: The number of uniformly distributed random bits representing a prime number.
//	/// - Returns a big integer.
//	func generatePrime(_ width: Int) -> BigUInt {
//		while true {
//			var random = BigUInt.randomInteger(withExactWidth: width + 1)
//			random |= BigUInt(1)
//			if random.isPrime() {
//				return random
//			}
//		}
//	}
//
//	/// Calculates and returns the `s` number that constitutes the private key.
//	func fetchUniqueDeviceSecret() throws -> BigUInt {
//		/// At the moment use only the device's vendor identifier as main secret.
//		// TODO: Use rest of secrets
//
//		/// Check whether deviceID is available and throw error if not.
//		/// If the value is nil, wait and get the value again later. This happens, for example, after the device has been restarted but before the user has unlocked the device.
//		guard let deviceID = secretManager.deviceID else {
//			throw FiatShamirError.unavailableDeviceID
//		}
//		/// Strips the `-` characters.
//		let deviceIDStripped = deviceID.replacingOccurrences(of: "-", with: "")
//		/// Convert the hexadecimal deviceID into a big integer.
//		guard let integerValue = BigUInt.init(deviceIDStripped, radix: 16) ?? BigUInt(deviceIDStripped, radix: 10) else {
//			throw FiatShamirError.couldNotConvertDeviceIDToInteger
//		}
//		return integerValue
//	}
//
//	/// Calculates and returns the protocol's `v` public key that uses the user and device secrets along with the `N` product of prime numbers.
//	/// Returns the big integer key in a `Data` value that contains the base-256 representation of this integer, in network (big-endian) byte order.
//	func generatePublicKeyV(n: BigUInt) throws -> Data {
//		/// Get the `s` secret number based on the unique device identifier (`VendorID`).
//		let s = try fetchUniqueDeviceSecret()
//		/// Calculate the public `v` key.
//		let v = s.power(2, modulus: n)
//		return v.serialize()
//	}
//}
