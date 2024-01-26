//
//  FiatShamir.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 24.01.24.
//

import Foundation
import BigInt
import Combine

/// The basic `Fiat-Shamir` zero-knowledge identification protocol implementation.
public class FiatShamir: ZeroKnowledgeProtocol {

	// MARK: Secret manager

	private(set) var secretManager: SecretManaging

	// MARK: - Private properties

	/// Configuration parameters required by the protocol (i.e. `N` coprime bit length).
	private let configuration: Config
	/// Establishes and maintains a `web-socket`connection sending the initially requested payload
	/// and identifying the device based on the given secrets.
	private let connection: WSConnectionProtocol
	/// A set storing the `cancellable` subscriber instances.
	private var cancelBag: Set<AnyCancellable> = []
	
	// MARK: - Initialization

	/// Creates an instace of a the basic `Fiat-Shamir` zero-knowledge identification protocol implementation.
	/// - Parameters:
	///   - secretManager: An object executing CRUD operations regarding user's and device's secrets.
	///   - configuration: Configuration parameters required by the protocol (i.e. `N` coprime bit length).
	///   - connection: Establishes and maintains a `web-socket`connection sending the initially requested payload
	/// and identifying the device based on the given secrets.
	init(
		secretManager: SecretManaging,
		configuration: Config,
		connection: WSConnectionProtocol
	) {
		self.secretManager = secretManager
		self.configuration = configuration
		self.connection = connection
		/// Set up observers to react on the verfier's requests for proof.
		setBindings()
	}

	// MARK: - ZeroKnowledgeProtocol
	
	func calculatePublicKey() throws -> PublicKey {
		let n = calculateN()
		let v = try calculateV()
		print("N == \(n)")
		return .init(v: v, n: n.serialize())
	}

	func register(payload: Data) throws {
		connection.start()
		let publicKey = try self.calculatePublicKey()
		let payload = RegistrationPayload(protocolType: ZkpFlavor.fiatShamir(config: configuration).name, payload: payload, key: publicKey)
		let encodedPayload = try JSONEncoder().encode(payload)
		connection.sendMessage(message: String(data: encodedPayload, encoding: .utf8) ?? "could not encode payload")
	}

	func initiateIdentification() {
	}
}

// MARK: - Public methods

public extension FiatShamir {
	/// Config parameters required by the protocol.
	struct Config: Codable {
		/// The number of bits of the `N` comprimes.
		/// - NOTE: An RSA minimum is from 1024 to 2048 bits.
		var coprimeWidth: Int
		
		public init(coprimeWidth: Int) {
			self.coprimeWidth = coprimeWidth
		}
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
	struct PublicKey: Codable {
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
		/// Strips the `-` characters.
		let deviceIDStripped = deviceID.replacingOccurrences(of: "-", with: "")
		/// Convert the hexadecimal deviceID into a big integer.
		guard let integerValue = BigUInt.init(deviceIDStripped, radix: 16) ?? BigUInt(deviceIDStripped, radix: 10) else {
			throw FiatShamirError.couldNotConvertDeviceIDToInteger
		}
		return integerValue
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

	/// Sets up required observers.
	/// One of them observes received messages through the `web-socket` connection used
	/// for the verification process.
	func setBindings() {
		connection.incomingMessagePublisher
			.sink { [weak self] result in
				print("--- did receive result: \(result)")
//				self?.connection.stop()
			} receiveValue: { [weak self] message in
				print("--- did receive message: \(message)")
//				self?.connection.stop()

			}.store(in: &cancelBag)
	}
}
