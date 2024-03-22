//
//  ZKPDevicePKProvider.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 17.03.24.
//

import Foundation

protocol ZKPDevicePKProvider {
	func fetchDeviceKey() throws -> Data
}
