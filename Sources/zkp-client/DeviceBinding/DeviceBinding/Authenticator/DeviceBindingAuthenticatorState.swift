//
//  DeviceBindingAuthenticatorState.swift
//  Brokerage
//
//  Created by Thomas Segkoulis on 15.03.24.
//

import Foundation
import CoreBluetooth

protocol DeviceBindingAuthenticatorStateProtocol {
	var context: DeviceBindingAuthenticatorStateContextProtocol? { get set }

	func start()
	func sendDTO(_ dto: DeviceBindingMessageDTO, toPeripheral peripheral: CBPeripheral, forCharacteristic characteristic: CBCharacteristic)
	func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
}

extension DeviceBindingAuthenticatorStateProtocol {
	func sendDTO(_ dto: DeviceBindingMessageDTO, toPeripheral peripheral: CBPeripheral, forCharacteristic characteristic: CBCharacteristic) {
		let data = try! JSONEncoder().encode(dto)
		let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
		var offset = 0
		while offset < data.count {
			let chunkSize = min(mtu, data.count - offset)
			let chunk = data.subdata(in: offset..<offset + chunkSize)
			peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
			offset += chunkSize
		}
		peripheral.writeValue("EOF".data(using: .utf8)!, for: characteristic, type: .withResponse)
	}}
