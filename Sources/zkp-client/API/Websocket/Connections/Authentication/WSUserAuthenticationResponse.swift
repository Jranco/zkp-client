//
//  WSUserAuthenticationResponse.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

struct WSUserAuthenticationResponse: Codable {
	var challenge: Int?
	var state: State
}

extension WSUserAuthenticationResponse {
	enum State: String, Codable {
		case pendingVerification
		case verificationInProgress
		case didFailToVerify
		case didVerifyWithSuccess
	}
}
