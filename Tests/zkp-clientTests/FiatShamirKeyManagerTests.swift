//
//  FiatShamirKeyManagerTests.swift
//  
//
//  Created by Thomas Segkoulis on 16.04.24.
//

import XCTest
@testable import zkp_client

final class FiatShamirKeyManagerTests: XCTestCase {

	func test_shouldAddPaddingToDeviceSecret() throws {
		/// GIVEN:
		let keyManager = FiatShamirKeyManager(coprimeWidth: 512, secretManager: SecretManagerMock(), userID: "tom")
		
		/// WHEN:
		let deviceID = try keyManager.fetchUniqueDeviceSecret()
		
		let numb = deviceID
		print("numb: \(numb)")
	}
	
	func test_shouldGenerateKey() async throws {
//		measure {
//			let key = try await FiatShamirKeyManager(coprimeWidth: <#Int#>, secretManager: SecretManagerMock(), userID: "tom1").generateDevicePublicKey()
//			print("key: \(key)")
//		}
		
//		measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
		print("did statr: \(Date())")
		let key = try await FiatShamirKeyManager(coprimeWidth: 2048, secretManager: SecretManagerMock(), userID: "tom1").generateDevicePublicKey()
		print("key: \(key)")

		print("did end: \(Date())")
//		}
	}
}
