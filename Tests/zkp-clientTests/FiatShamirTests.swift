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
		
		let n = BigUInt(integerLiteral: 468)
		let serialized = n.serialize()
		let deserialized = serialized.base64EncodedString()
		print("deserialized: \(deserialized)")
//		let intDes = BigInt.ini
		
		
		
	}
}

// MARK: - Mock/Fake

struct SecretManagerMock: SecretManaging {
	var deviceID: String?
	
	func upsertSecret<SecretID>(with id: SecretID, userID: String, buffer: UnsafeRawBufferPointer?) where SecretID : Hashable {}
	
	func upsertSecret<SecretID>(with id: SecretID, userID: String, intValue: Int) where SecretID : Hashable {}
	
	func upsertSecret<SecretID>(with id: SecretID, userID: String, stringValue: String) where SecretID : Hashable {}
	
	func upsertSecret<SecretID, SecretValue>(with id: SecretID, userID: String, value: SecretValue) where SecretID : Hashable, SecretValue : Hashable {}
}
