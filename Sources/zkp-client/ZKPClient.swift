//
//  ZKPClient.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 21.01.24.
//

import Foundation

public struct ZKPClient {
	
	let znp: FiatShamir
	
	public init() throws {
		let secretManager = SecretManager()
		let config = FiatShamir.Config(coprimeWidth: 5)
		let connection = try WSConnection(config: .init(path: "ws://192.168.178.52:8010/authenticate/"))
		let znp = FiatShamir(secretManager: secretManager, configuration: config, connection: connection)
		self.znp = znp
	}

	public func sendRegistration() throws {
		try znp.register()
	}
}
