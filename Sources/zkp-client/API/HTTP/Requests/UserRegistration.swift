//
//  UserRegistration.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

struct UserRegistration: RestRequestProtocol {
	var base: String
	var path: String
	var queryItems: [URLQueryItem]?
	var method: HTTPMethod { .POST }
	var body: Data?
}
