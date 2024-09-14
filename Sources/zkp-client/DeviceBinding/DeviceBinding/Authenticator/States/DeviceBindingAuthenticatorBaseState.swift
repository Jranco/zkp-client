//
//  DeviceBindingAuthenticatorBaseState.swift
//	zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation
import CoreBluetooth

class DeviceBindingAuthenticatorBaseState: DeviceBindingAuthenticatorStateProtocol {
	weak var context: DeviceBindingAuthenticatorStateContextProtocol?
	func start() {}
	func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {}
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {}
}
