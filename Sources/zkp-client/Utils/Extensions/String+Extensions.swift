//
//  String+Extensions.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 05.02.24.
//

extension String {
	func toHex() -> String {
		return self.utf8.map { String(format: "%02X", $0) }.joined()
	}
}
