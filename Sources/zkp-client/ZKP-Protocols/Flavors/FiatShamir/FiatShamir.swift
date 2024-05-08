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
	private(set) var keyManager: FiatShamirKeyManager
	/// An object executing CRUD operations in secure storage.
	private(set) var secureStorage: SecureStorageManaging
	/// Contains api related configuration.
	private(set) var apiConfig: APIConfigurating

	// MARK: - Private properties

	/// Configuration parameters required by the protocol (i.e. `N` coprime bit length).
	private let configuration: Config
	/// Establishes and maintains a `web-socket`connection sending the initially requested payload
	/// and identifying the device based on the given secrets.
	private let authenticationConnection: WSConnection<WSUserVerificationResponse>
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
		secureStorage: SecureStorageManaging,
		configuration: Config,
		apiConfig: APIConfigurating
	) throws {
		self.userID = userID
		self.configuration = configuration
		self.keyManager = FiatShamirKeyManager(coprimeWidth: configuration.coprimeWidth, secretManager: secretManager, userID: userID)
		self.secureStorage = secureStorage
		// TODO: Use `bindNewDevice` for binding new device
		let authenticationConnectionConfig = WSUserAuthentication(base: apiConfig.baseWSURL, path: "/authenticate/")
//		let authenticationConnectionConfig = WSUserAuthentication(base: apiConfig.baseWSURL, path: "/bindNewDevice/")

		self.authenticationConnection = try WSConnection(config: authenticationConnectionConfig)
		self.apiConfig = apiConfig
		/// Set up observers to react on the verfier's requests for proof.
		setBindings()
	}

	// MARK: - ZeroKnowledgeProtocol

	@MainActor
	func register(payload: Data) async throws {
		/// Calculate public key based on secrets and unique device identifiers.
		let publicKey = try await keyManager.generateDevicePublicKey()
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
					try secureStorage.upsert(key: "zkn_public_key", value: publicKeyData)
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
		/// Start WS connection
		authenticationConnection.start()

		// TODO: Throw error in case device is not binded
		/// Try getting the already stored (unique) device public key. In the future also the `registration` timestamp to be used as a secret
		/// and other user's secrets
		let keyData = try? secureStorage.getValue(key: "zkn_public_key")
		let publicKey = try! JSONDecoder().decode(PublicKey.self, from: keyData!)
		let n = BigUInt(publicKey.nKey)

		/// Calculate random session number that initiates the verification process.
		let r = BigUInt.randomInteger(withExactWidth: keyManager.coprimeWidth)
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

		/// Send an authentication request initiating the `zkp` verification process.
		authenticationConnection.sendMessage(message: String(data: encodedPayload, encoding: .utf8) ?? "could not encode payload")
	}

	func bindDevice(payload: Data, otherDeviceKey: Data) async throws {
		/// Start WS connection
		authenticationConnection.start()
		
		// TODO: Throw error in case device is not binded
		/// Try getting the already stored (unique) device public key. In the future also the `registration` timestamp to be used as a secret
		/// and other user's secrets
		let keyData = try? secureStorage.getValue(key: "zkn_public_key")
		let publicKey = try! JSONDecoder().decode(PublicKey.self, from: keyData!)
		let n = BigUInt(publicKey.nKey)
		
		/// Calculate random session number that initiates the verification process.
		let r = BigUInt.randomInteger(withExactWidth: keyManager.coprimeWidth/2)
		let initiatingRandomNum = r.power(2, modulus: n)
		self.initiatingRandomNum = r
		
		let authPayload = AuthenticationPayload(protocolType: ZkpFlavor.fiatShamir(config: configuration).name,
												payload: payload,
												userID: userID,
												key: publicKey,
												initiatingNum: initiatingRandomNum.serialize(),
												challengeResponse: Data())
		let payload = DeviceBindingPayload(newDeviceKey: otherDeviceKey, authenticationPayload: authPayload)
		let encodedPayload = try JSONEncoder().encode(payload)
		
		/// Send an authentication request initiating the `zkp` verification process.
		authenticationConnection.sendMessage(message: String(data: encodedPayload, encoding: .utf8) ?? "could not encode payload")
	}

	// MARK: - ZKPDevicePKProvider
	
	func fetchDeviceKey() async throws -> Data {
		let key = try await self.keyManager.generateDevicePublicKey()
		let keyData = try JSONEncoder().encode(key)
		// TODO: Upsert it after an operation is finished with success. The following upsert was used as a quick way to test new device binding from the client side.
		try secureStorage.upsert(key: "zkn_public_key", value: keyData)
		print("--- Did store new credential to Keychain: \(Date())")
		return keyData
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
			} receiveValue: { [weak self] response in
				switch response.state {
				case .pendingVerification: break
				case .didVerifyWithSuccess:
					self?.authenticationConnection.stop()
				case .didFailToVerify:
					self?.authenticationConnection.stop()
				case .verificationInProgress:

					if 
						let self = self,
						let challenge = response.challenge,
						let challengeResponse = self.challengeResponse(from: challenge)
					{
						authenticationConnection.sendMessage(message: String(data: challengeResponse, encoding: .utf8) ?? "could not encode payload")
					} else {
						// TODO: Handle error
					}
				}
			}.store(in: &cancelBag)
	}

	private func challengeResponse(from challenge: Int) -> Data? {
		guard
			let initiatingRandomNum = initiatingRandomNum,
			let secret = try? self.keyManager.fetchUniqueDeviceSecret()
		else {
			return nil
		}
		let keyData = try? secureStorage.getValue(key: "zkn_public_key")
		let keyDecoded = try? JSONDecoder().decode(PublicKey.self, from: keyData!)
		let n = BigUInt(keyDecoded!.nKey)
		let secretPower = secret.power(challenge)
		let yy = initiatingRandomNum.multiplied(by: secretPower)
		let y = yy.power(1, modulus: n)

		let challengeResponse = ChallengePayload(challengeResponse: y.serialize())
		let encodedPayload = try! JSONEncoder().encode(challengeResponse)
		return encodedPayload
	}
}
