//
//  UUID+Extensions.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import Foundation

extension UUID {
	/// Converts the string representation of the `UUID` to a hexadecimal string.
	func toHex() -> String? {
		/// Remove dashes from the UUID string.
		let strippedString = uuidString.replacingOccurrences(of: "-", with: "")
		/// Convert the stripped UUID string to hexadecimal.
		if let uuidData = Data.init(base64Encoded: strippedString) {
			let hexString = uuidData.map { String(format: "%02x", $0) }.joined(separator: "")
			return hexString
		} else {
			return nil
		}
	}
}
