//
//  FiatShamirTests.swift
//  zkp-clientTests
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import XCTest
import Foundation
import BigInt
@testable import zkp_client

final class FiatShamirTests: XCTestCase {
	func test_shouldCalculatePublicKey() throws {
//		/// GIVEN: A secret manager
//		let secretManager = SecretManagerMock(deviceID: "34567890ABCDEF12")
//		/// AND: The protocol executor
//		let zkp = FiatShamir(secretManager: secretManager, configuration: .init(coprimeWidth: 1024))
//		
//		/// WHEN: Calculating the public key
//		let publicKey = try zkp.calculatePublicKey()
//		print("publicKey: \(publicKey)")
		
		let uuidStr = "5D1C574AC9B942D89B861CCD72552A13"
		
		let data = Data(base64Encoded: uuidStr)
		print("data: \(data)")
//		let int = UINT
		
		let n = BigUInt.randomInteger(withExactWidth: 1024)
		print("ïnit n: \(n)")
		let serialized = n.serialize()
		let deserialized = serialized.base64EncodedString()
		print("deserialized: \(deserialized)")
//		let intDes = BigUInt.init(String(data: serialized, encoding: .utf8)!, radix: 256)
//		print("intDes: \(intDes)")
		
//		let reversedBytes = serialized.reversed().map { UInt8(String($0))! }
		let final = BigUInt(serialized)
		print("final: \(final)")
	}
	
	func test_createValuesForAPItests() throws {
		let vInt = BigUInt.init(integerLiteral: 302)
		let nInt = BigUInt.init(integerLiteral: 323)
		let initiatingInt = BigUInt.init(integerLiteral: 144)

		let key = FiatShamir.PublicKey(vKey: vInt.serialize(), nKey: nInt.serialize())
		let keyContainer = FiatShamir.KeyContainer(device: key, other: [])
//		let authDTO = RegistrationPayload(protocolType: "fiatShamir",
//										  payload: "some-auth-data".data(using: .utf8)!,
//										  userID: "DummyUser",
//										  key: keyContainer)
		
		let authDTO = AuthenticationPayload(protocolType: "fiatShamir", 
											payload: "some-auth-data".data(using: .utf8)!,
											userID: "DummyUser",
											key: keyContainer,
											initiatingNum: initiatingInt.serialize(),
											challengeResponse: Data())
		let encodedData = try JSONEncoder().encode(authDTO)
		let str = String(data: encodedData, encoding: .utf8)
		print("-- str: \(str)")
		
		
		
		let challengeResponse = ChallengePayload(challengeResponse: BigUInt.init(integerLiteral: 12).serialize())
		let encodedPayload = try! JSONEncoder().encode(challengeResponse)
		let str2 = String(data: encodedPayload, encoding: .utf8)

		print("-- response: \(str2)")

	}
}

// MARK: - Mock/Fake

struct SecretManagerMock: SecretManaging {
	var deviceID: String? {
		"5D1C574AC9B942D89B861CCD72552A13"
	}
	
	func upsertSecret<SecretID>(with id: SecretID, userID: String, buffer: UnsafeRawBufferPointer?) where SecretID : Hashable {}
	
	func upsertSecret<SecretID>(with id: SecretID, userID: String, intValue: Int) where SecretID : Hashable {}
	
	func upsertSecret<SecretID>(with id: SecretID, userID: String, stringValue: String) where SecretID : Hashable {}
	
	func upsertSecret<SecretID, SecretValue>(with id: SecretID, userID: String, value: SecretValue) where SecretID : Hashable, SecretValue : Hashable {}
}
