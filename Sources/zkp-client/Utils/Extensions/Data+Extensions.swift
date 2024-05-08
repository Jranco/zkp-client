//
//  Data+Extensions.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 19.04.24.
//

import Foundation

extension Data {
	func firstNBits(_ n: Int) -> Data? {
		guard n > 0 && n <= count * 8 else {
			return nil
		}
		
		let bytesToRead = (n + 7) / 8 // Calculate number of bytes to read
		var resultData = Data()
		
		for i in 0..<bytesToRead {
			let byteIndex = i / 8
			let bitIndex = UInt8(7 - (i % 8))
			let byte = self[byteIndex] >> bitIndex & 0x01 // Extract bit
			resultData.append(byte)
		}
		
		return resultData
	}
}
