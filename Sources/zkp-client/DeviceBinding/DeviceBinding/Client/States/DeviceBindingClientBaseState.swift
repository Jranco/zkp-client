//
//  DeviceBindingClientBaseState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation
import CoreBluetooth
import OSLog

class DeviceBindingClientBaseState: DeviceBindingClientStateProtocol {

	weak var context: DeviceBindingClientStateContextProtocol?
	var responseData: Data = Data()
	var responseDataOffset = 0
	var didFinishSendingData: Bool = false
	var peripheralManager: CBPeripheralManager
	var transferCharacteristic: CBMutableCharacteristic?
	var connectedCentral: CBCentral?

	func start() {}
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {}
//	func sendDTO(_ dto: DeviceBindingMessageDTO, toPeripheral peripheralManager: CBPeripheralManager, forCharacteristic characteristic: CBMutableCharacteristic) {}
	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {}
	func didFinishSendingDataWithSuccess() {}

	init(
		peripheralManager: CBPeripheralManager,
		transferCharacteristic: CBMutableCharacteristic?,
		connectedCentral: CBCentral?
	) {
		self.peripheralManager = peripheralManager
		self.transferCharacteristic = transferCharacteristic
		self.connectedCentral = connectedCentral
	}

	func sendDataIfNeeded() {
		guard
			let transferCharacteristic = transferCharacteristic,
			let connectedCentral = connectedCentral
		else {
			return
		}

		guard responseDataOffset < responseData.count else {
			if didFinishSendingData == false {
				let result = peripheralManager.updateValue("EOF".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
				if result == true {
					Logger.deviceBinding.debug("== ok did send repsonse EOF")
					didFinishSendingData = true
					didFinishSendingDataWithSuccess()
				} else {
					Logger.deviceBinding.debug("== did fail to ack EOF repsonse")
				}
			}
			return
		}

		let mtu = connectedCentral.maximumUpdateValueLength
		let dataRemainingToSend = responseData.count - responseDataOffset
		let minDataToSend = min(mtu,dataRemainingToSend)
		let dataToSend = responseData.subdata(in: responseDataOffset..<responseDataOffset + minDataToSend)
		let result = peripheralManager.updateValue(dataToSend, for: transferCharacteristic, onSubscribedCentrals: nil)
		if result == true {
			Logger.deviceBinding.debug("== ok did send repsonse")
			responseDataOffset += minDataToSend
			sendDataIfNeeded()
		} else {
			Logger.deviceBinding.debug("== did fail to send repsonse")
		}
	}

}
