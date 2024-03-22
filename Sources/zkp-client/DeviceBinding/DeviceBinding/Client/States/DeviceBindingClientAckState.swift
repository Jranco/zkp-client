//
//  DeviceBindingClientAckState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation
import CoreBluetooth
import OSLog

class DeviceBindingClientAckState: DeviceBindingClientBaseState {
	
	private var synData = Data()
//	private var peripheralManager: CBPeripheralManager
//	private var transferCharacteristic: CBMutableCharacteristic?
//	private var connectedCentral: CBCentral?
//	private var responseDataOffset = 0
//	private var didFinishSendingData: Bool = false

	private var responseDataWhatever: DeviceBindingMessageDTO {
		let data = "Cupcake pie soufflé wafer cake marshmallow apple pie. Pudding toffee marshmallow chocolate candy chocolate liquorice. Oat cake topping brownie gingerbread chocolate bar soufflé chocolate. Muffin candy danish lemon drops tart sugar plum jujubes chocolate. Danish gummies sweet roll chocolate bar jujubes. Lollipop cotton candy gummies tiramisu danish icing donut. Halvah bonbon gingerbread gummi bears jujubes topping. Marzipan wafer sugar plum gummi bears donut jelly beans candy soufflé. Macaroon sugar plum sweet cotton candy cake wafer chocolate bar candy canes gummies. Jelly beans chocolate bar powder cheesecake bonbon cake liquorice donut jelly. Jelly-o donut biscuit lollipop ice cream. Sweet toffee sesame snaps cake dessert. Jujubes tootsie roll chocolate cake danish bear claw jelly carrot cake brownie. Powder tiramisu sugar plum fruitcake biscuit sugar plum topping cotton candy. Gingerbread danish oat cake caramels shortbread caramels cake chupa chups pie. Gingerbread marshmallow gummies oat cake cupcake sesame snaps chocolate bar. Sugar plum marzipan sweet icing topping.".data(using: .utf8)!
		return DeviceBindingMessageDTO(messageType: .ack, payload: data)
	}
	
	override init(
		peripheralManager: CBPeripheralManager,
		transferCharacteristic: CBMutableCharacteristic?,
		connectedCentral: CBCentral?
	) {
//		self.peripheralManager = peripheralManager
//		self.transferCharacteristic = transferCharacteristic
//		self.connectedCentral = connectedCentral
		super.init(peripheralManager: peripheralManager, transferCharacteristic: transferCharacteristic, connectedCentral: connectedCentral)
		self.responseData = try! JSONEncoder().encode(responseDataWhatever)
	}
	
	override func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
		sendDataIfNeeded()
//		let didSend = peripheral.updateValue("EOF".data(using: .utf8)!, for: transferCharacteristic!, onSubscribedCentrals: nil)
//		
//		if didSend {
//			Logger.deviceBinding.debug("== ok did send EOF repsonse")
//		} else {
//			Logger.deviceBinding.debug("== did fail to send EOF repsonse")
//		}
	}

	override func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {

		for aRequest in requests {
			guard let requestValue = aRequest.value,
				  let stringFromData = String(data: requestValue, encoding: .utf8) else {
				continue
			}
			Logger.deviceBinding.debug("did receive value: \(stringFromData, privacy: .public)")
			if stringFromData != "EOF" {
				self.synData.append(requestValue)
				self.peripheralManager.respond(to: aRequest, withResult: .success)
			} else {
				self.peripheralManager.respond(to: aRequest, withResult: .success)
				do {
					let decoded = try JSONDecoder().decode(DeviceBindingMessageDTO.self, from: synData)
					let payloadStr = String(data: decoded.payload, encoding: .utf8)
					Logger.deviceBinding.debug("did decode msg type \(decoded.messageType.rawValue, privacy: .public), with payload \(payloadStr!, privacy: .public)")
					Logger.deviceBinding.debug("did receive EOF: \(stringFromData, privacy: .public)")
					sendDataIfNeeded()
				} catch {
					Logger.deviceBinding.debug("error decoding data : \(error.localizedDescription, privacy: .public)")
				}
			}
		}
	}
	
	override func didFinishSendingDataWithSuccess() {
		let newState = DeviceBindingClientSharingPKState(
			peripheralManager: peripheralManager,
			transferCharacteristic: transferCharacteristic,
			connectedCentral: connectedCentral,
			devicePK: context!.devicePK)
		context?.changeState(state: newState)
	}

//	func sendDataIfNeeded() {
//		guard
//			let transferCharacteristic = transferCharacteristic,
//			let connectedCentral = connectedCentral
//		else {
//			return
//		}
//
//		guard responseDataOffset < responseData.count else {
//			if didFinishSendingData == false {
//				let result = peripheralManager.updateValue("EOF".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
//				if result == true {
//					Logger.deviceBinding.debug("== ok did send repsonse EOF")
//					didFinishSendingData = true
//				} else {
//					Logger.deviceBinding.debug("== did fail to ack EOF repsonse")
//				}
//			}
//			return
//		}
//
//		let mtu = connectedCentral.maximumUpdateValueLength
//		let dataRemainingToSend = responseData.count - responseDataOffset
//		let minDataToSend = min(mtu,dataRemainingToSend)
//		let dataToSend = responseData.subdata(in: responseDataOffset..<responseDataOffset + minDataToSend)
//		let result = peripheralManager.updateValue(dataToSend, for: transferCharacteristic, onSubscribedCentrals: nil)
//		if result == true {
//			Logger.deviceBinding.debug("== ok did send repsonse")
//			responseDataOffset += minDataToSend
//			sendDataIfNeeded()
//		} else {
//			Logger.deviceBinding.debug("== did fail to send repsonse")
//		}
//	}
}
