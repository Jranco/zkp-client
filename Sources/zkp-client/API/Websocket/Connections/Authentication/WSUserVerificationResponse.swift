//
//  WSUserVerificationResponse.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

struct WSUserVerificationResponse: Codable {
	var challenge: Int?
	var state: State
}

extension WSUserVerificationResponse {
	enum State: String, Codable {
		case pendingVerification
		case verificationInProgress
		case didFailToVerify
		case didVerifyWithSuccess
	}
}
