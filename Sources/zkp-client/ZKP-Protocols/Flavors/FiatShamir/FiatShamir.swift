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

	// MARK: - ZeroKnowledgeProtocol
	
	/// An object managing and generating the private/public keys required by the FiatShamir identification protocol.
	internal var keyManager: FiatShamirKeyManager

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
	private var apiConfig: APIConfigurating

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
		self.configuration = configuration
		self.keyManager = FiatShamirKeyManager(coprimeWidth: configuration.coprimeWidth, secretManager: secretManager, userID: userID)
		let authenticationConnectionConfig = WSUserAuthentication(base: apiConfig.baseWSURL, path: "/authenticate/")
		self.authenticationConnection = try WSConnection(config: authenticationConnectionConfig)
		self.apiConfig = apiConfig
		/// Set up observers to react on the verfier's requests for proof.
		setBindings()
	}

	// MARK: - ZeroKnowledgeProtocol

	func register(payload: Data) async throws {
		/// Calculate public key based on secrets and unique device identifiers.
		let publicKey = try keyManager.generateDevicePublicKey()
		let keyContainer = KeyContainer(device: publicKey, other: [publicKey, publicKey])
		/// Construct the payload to be sent as message.
		let payload = RegistrationPayload(protocolType: ZkpFlavor.fiatShamir(config: configuration).name,
										  payload: payload,
										  userID: userID,
										  key: keyContainer)
		let encodedPayload = try JSONEncoder().encode(payload)
		
		var request = UserRegistration(base: self.apiConfig.baseHTTPURL, path: "/register")
		request.body = encodedPayload
		let response = try await request.execute()
		if let httpResponse = response.1 as? HTTPURLResponse {
			if httpResponse.statusCode == 200 {
				do {
					let publicKeyData = try JSONEncoder().encode(publicKey)
					try KeychainManager(userID: userID).upsert(key: "zkn_public_key", value: publicKeyData)
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

	func authenticate(payload: Data) async throws {
		authenticationConnection.start()
		// TODO: Throw error in case device is not binded
		let publicKey = try fetchDeviceKey(for: userID)
		let n = BigUInt(publicKey.nKey)

		/// Calculate number that initiates the verification process.
		let r = BigUInt.randomInteger(withExactWidth: configuration.coprimeWidth/2)
		let initiatingRandomNum = r.power(2, modulus: n)
		self.initiatingRandomNum = r
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
	
	struct KeyContainer: Codable {
		/// A public key pair (`V`and `N`) derived from a unique device identifier.
		var device: PublicKey
		/// An array of other public key pairs (`V`and `N`) injected by the user and/or based on the environment where/when the registration occured.
		var other: [PublicKey]
	}
}

// MARK: - Private methods

private extension FiatShamir {

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
								if let secret = try? self.keyManager.fetchUniqueDeviceSecret() {
									let keyData = try? KeychainManager(userID: self.userID).getValue(key: "zkn_public_key")
									let keyDecoded = try? JSONDecoder().decode(PublicKey.self, from: keyData!)
									let n = BigUInt(keyDecoded!.nKey)
									let secretPower = secret.power(challenge)
									let yy = initiatingRandomNum.multiplied(by: secretPower)
									let y = yy.power(1, modulus: n)

									let challengeResponse = ChallengePayload(challengeResponse: y.serialize())
									let encodedPayload = try! JSONEncoder().encode(challengeResponse)
									/// Sends an authentication request initiating the `zkp` verification process.
									authenticationConnection.sendMessage(message: String(data: encodedPayload, encoding: .utf8) ?? "could not encode payload")
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
}
