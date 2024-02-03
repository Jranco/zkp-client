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
	private let authenticationConnection: WSConnection<WSUserAuthenticationResponse>
	/// A set storing the `cancellable` subscriber instances.
	private var cancelBag: Set<AnyCancellable> = []
	/// Unique user identifier.
	private var userID: String
	private var initiatingRandomNum: BigUInt?

	// MARK: - Initialization

	/// Creates an instace of a the basic `Fiat-Shamir` zero-knowledge identification protocol implementation.
	/// - Parameters:
	///   - userID: Unique user identifier.
	///   - secretManager: An object executing CRUD operations regarding user's and device's secrets.
	///   - configuration: Configuration parameters required by the protocol (i.e. `N` coprime bit length).
	///   - apiConfig: Remote server configuration providing the `api`  and `websocket` services.
	init(
		userID: String,
		secretManager: SecretManaging,
		configuration: Config,
		apiConfig: APIConfigurating
	) throws {
		self.userID = userID
		self.secretManager = secretManager
		self.configuration = configuration
		let authenticationConnectionConfig = WSUserAuthentication(base: apiConfig.baseURL, path: "/authenticate/")
		self.authenticationConnection = try WSConnection(config: authenticationConnectionConfig)
		/// Set up observers to react on the verfier's requests for proof.
		setBindings()
	}

	// MARK: - ZeroKnowledgeProtocol
	
	func generatePublicKey() throws -> PublicKey {
		let n = generatePublicKeyN()
		let v = try generatePublicKeyV(n: n)
		return .init(vKey: v, nKey: n.serialize())
	}

	func register(payload: Data) async throws {
		/// Calculate public key based on secrets and unique device identifiers.
		let publicKey = try self.generatePublicKey()
		/// Construct the payload to be sent as message.
		let payload = RegistrationPayload(protocolType: ZkpFlavor.fiatShamir(config: configuration).name,
										  payload: payload,
										  userID: userID,
										  key: publicKey)
		let encodedPayload = try JSONEncoder().encode(payload)
		
		var request = UserRegistration(base: "http://192.168.178.52:8012", path: "/register")
		request.body = encodedPayload
		let response = try await request.execute()
		if let httpResponse = response.1 as? HTTPURLResponse {
			if httpResponse.statusCode == 200 {
				do {
					let publicKeyData = try JSONEncoder().encode(publicKey)
					try KeychainManager(userID: userID).upsert(key: "zkn_public_key", value: publicKeyData)
					
					let v = BigUInt(publicKey.vKey)
					let n = BigUInt(publicKey.nKey)
					print("Storing: v: \(v)\n\n n: \(n)\n\n")
					try storeDevice(key: publicKey, for: userID)
					print("--- Did store new credential to Keychain: \(Date())")
				} catch {
					print("--- eror storing to Keychain: \(error)")
				}
			} else {
				print("--- FiatShamir.register... user exists")
			}
		}
	}
	
	private func storeDevice(key: PublicKey, for userID: String) throws {
		let keychainManager = KeychainManager(userID: userID)
		try keychainManager.upsert(key: FiatShamirKeyName.v, value: key.vKey)
		try keychainManager.upsert(key: FiatShamirKeyName.n, value: key.nKey)
	}

	private func fetchDeviceKey(for userID: String) throws -> PublicKey {
			let keychainManager = KeychainManager(userID: userID)
			let storedDataV = try keychainManager.getValue(key: FiatShamirKeyName.v)
			let storedDataN = try keychainManager.getValue(key: FiatShamirKeyName.n)
		
			return .init(vKey: storedDataV, nKey: storedDataN)
	}

	func authenticate(payload: Data) async throws {
		authenticationConnection.start()
		// TODO: Throw error in case device is not binded
		let publicKey = try fetchDeviceKey(for: userID)
		let v = BigUInt(publicKey.vKey)
		let n = BigUInt(publicKey.nKey)

		/// Calculate number that initiates the verification process.
		let r = BigUInt.randomInteger(withExactWidth: configuration.coprimeWidth/2)
		let initiatingRandomNum = r.power(2, modulus: n)
		self.initiatingRandomNum = r
		print("-- did creating init random num: \(initiatingRandomNum)")
		/// Construct the payload to be sent as message.
		let payload = AuthenticationPayload(protocolType: ZkpFlavor.fiatShamir(config: configuration).name,
											payload: payload,
											userID: userID,
											key: publicKey, 
											initiatingNum: initiatingRandomNum.serialize(), 
											challengeResponse: Data())
		let encodedPayload = try JSONEncoder().encode(payload)
		/// Sends an authentication request initiating the `zkp` verification process.
		authenticationConnection.sendMessage(message: String(data: encodedPayload, encoding: .utf8) ?? "could not encode payload")
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
		var vKey: Data
		/// The `N` product of two big prime numbers (p x q) that constitutes the public key.
		var nKey: Data
	}
}

// MARK: - Private methods

private extension FiatShamir {
	/// Calculates and returns the `N` product of two big prime numbers (p x q) that constitutes the public key.
	func generatePublicKeyN() -> BigUInt {
		let p = generatePrime(configuration.coprimeWidth)
		let q = generatePrime(configuration.coprimeWidth)
		return p.multiplied(by: q)
	}

	/// Generates a random prime number.
	/// - Parameter width: The number of uniformly distributed random bits representing a prime number.
	/// - Returns a big integer.
	func generatePrime(_ width: Int) -> BigUInt {
		while true {
			var random = BigUInt.randomInteger(withExactWidth: width + 1)
			random |= BigUInt(1)
			if random.isPrime() {
				return random
			}
		}
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
		/// Convert the hexadecimal deviceID into a big integer.
		guard let integerValue = BigUInt.init(deviceIDStripped, radix: 16) ?? BigUInt(deviceIDStripped, radix: 10) else {
			throw FiatShamirError.couldNotConvertDeviceIDToInteger
		}
		return integerValue
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

	/// Sets up required observers.
	/// One of them observes received messages through the `web-socket` connection used
	/// for the verification process.
	func setBindings() {
		authenticationConnection.incomingMessagePublisher
			.sink { [weak self] result in
				self?.authenticationConnection.stop()
				print("--- incomingMessagePublisher result: \(result)")
			} receiveValue: { [weak self] response in
				switch response.state {
				case .pendingVerification: 
					print("--- incomingMessagePublisher.pendingVerification")
				case .didVerifyWithSuccess:
					print("--- incomingMessagePublisher.didVerifyWithSuccess")
					self?.authenticationConnection.stop()
				case .didFailToVerify:
					print("--- incomingMessagePublisher.didFailToVerify")
					self?.authenticationConnection.stop()
				case .verificationInProgress:
					print("--- incomingMessagePublisher.verificationInProgress")

					if let self = self {
						if let challenge = response.challenge {
							if let initiatingRandomNum = initiatingRandomNum {
								if let secret = try? fetchUniqueDeviceSecret() {
									let keyData = try? KeychainManager(userID: self.userID).getValue(key: "zkn_public_key")
									////							print("=+++ the private keys: \keyData")
									let keyDecoded = try? JSONDecoder().decode(PublicKey.self, from: keyData!)
									let v = BigUInt(keyDecoded!.vKey)
									let n = BigUInt(keyDecoded!.nKey)
									print("!!!!!! ee: \(challenge)")
									let secretPower = secret.power(challenge)
									let yy = initiatingRandomNum.multiplied(by: secretPower)
									let y = yy.power(1, modulus: n)
									print("-- y:\(y)")
									print("-- yˆ2modN = \(y.power(2))")
//									print("-- yˆ2modN = \(y.power(2, modulus: n))")
//									let xu = (self.initiatingRandomNum!.multiplied(by: v)).power(1, modulus: n)
									let rr = self.initiatingRandomNum!.power(2, modulus: n)
									let xu = (rr.multiplied(by: v.power(challenge)))
									print("-- xu = \(xu)")
									let challengeResponse = ChallengePayload(challengeResponse: y.serialize())
									let encodedPayload = try! JSONEncoder().encode(challengeResponse)
									/// Sends an authentication request initiating the `zkp` verification process.
									authenticationConnection.sendMessage(message: String(data: encodedPayload, encoding: .utf8) ?? "could not encode payload")
									
									//							print("v: \(v)\n\n n: \(n)\n\n")
									
								}
							} else {
								print("--- Error, is missing initial random number `r`")
							}
						} else {
							// TODO: throw error
							print("--- Error, did start verification process but challenge is missing")
						}
					}
				}
			}.store(in: &cancelBag)
	}
}
