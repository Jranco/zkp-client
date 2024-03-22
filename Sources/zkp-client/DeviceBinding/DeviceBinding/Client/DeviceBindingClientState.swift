//
//  DeviceBindingClientState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 15.03.24.
//

import Foundation
import CoreBluetooth

protocol DeviceBindingClientStateProtocol {
	var context: DeviceBindingClientStateContextProtocol? { get set }

	func start()
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
//	func sendDTO(_ dto: DeviceBindingMessageDTO, toPeripheral peripheralManager: CBPeripheralManager, forCharacteristic characteristic: CBMutableCharacteristic)
	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager)
	func didFinishSendingDataWithSuccess()
}
