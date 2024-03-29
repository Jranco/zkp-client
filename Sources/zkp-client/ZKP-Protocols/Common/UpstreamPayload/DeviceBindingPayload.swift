//
//  DeviceBindingPayload.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 25.03.24.
//

import Foundation

struct DeviceBindingPayload<Key: Codable>: Codable {
	var newDeviceKey: Data
	var authenticationPayload: AuthenticationPayload<Key>
}
