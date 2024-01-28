//
//  WSConnectionResponse.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

struct WSConnectionResponse<Payload: Codable>: Codable {
	var status: Int
	var payload: Payload?
}
