//
//  FiatShamirTests.swift
//  zkp-clientTests
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import XCTest
@testable import zkp_client

final class FiatShamirTests: XCTestCase {
	func test_shouldCalculatePublicKey() throws {
		/// GIVEN: A secret manager
		let secretManager = SecretManagerMock(deviceID: "34567890ABCDEF12")
		/// AND: The protocol executor
		let zkp = FiatShamir(secretManager: secretManager, configuration: .init(coprimeWidth: 1024))
		
		/// WHEN: Calculating the public key
		let publicKey = try zkp.calculatePublicKey()
		print("publicKey: \(publicKey)")
		
		
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
