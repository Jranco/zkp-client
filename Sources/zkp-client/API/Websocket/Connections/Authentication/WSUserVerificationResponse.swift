//
//  WSUserVerificationResponse.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

/// The response of the server during the interactive verification phase.
struct WSUserVerificationResponse: Codable {
	/// The challenge the server sends to the client to verify it.
	var challenge: Int?
	var state: State
}

extension WSUserVerificationResponse {
	/// State of the verification.
	enum State: String, Codable {
		case pending
		case verificationInProgress
		case didFailToVerify
		case didVerifyWithSuccess
	}
}
