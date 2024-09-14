//
//  DeviceBindingClientSharingPKState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 17.03.24.
//

import Foundation
import CoreBluetooth
import OSLog
import CryptoKit

class DeviceBindingClientSharingPKState: DeviceBindingClientBaseState {
	
	var requestToShareKeyData = Data()
	var devicePK: Data
	var symmetricKey: SymmetricKey
	
	override var context: DeviceBindingClientStateContextProtocol? {
		didSet {
			let encryptedZKPKey = self.encryptData(data: self.context!.devicePK, key: symmetricKey)
			let dto = DeviceBindingMessageDTO(messageType: .sendingPK, payload: encryptedZKPKey!)
			self.responseData = try! JSONEncoder().encode(dto)
		}
	}
	
	init(
		peripheralManager: CBPeripheralManager,
		transferCharacteristic: CBMutableCharacteristic?,
		connectedCentral: CBCentral?,
		devicePK: Data,
		symmetricKey: SymmetricKey
	) {
		self.devicePK = devicePK
		self.symmetricKey = symmetricKey
		super.init(peripheralManager: peripheralManager, transferCharacteristic: transferCharacteristic, connectedCentral: connectedCentral)
	}

	override func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
		sendDataIfNeeded()
	}
	
	override func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {

		for aRequest in requests {
			guard let requestValue = aRequest.value,
				  let stringFromData = String(data: requestValue, encoding: .utf8) else {
				continue
			}
			if stringFromData != "EOF" {
				self.requestToShareKeyData.append(requestValue)
				self.peripheralManager.respond(to: aRequest, withResult: .success)
			} else {
				self.peripheralManager.respond(to: aRequest, withResult: .success)
				do {
					let decoded = try JSONDecoder().decode(DeviceBindingMessageDTO.self, from: requestToShareKeyData)

					do {
						let decryptedData = try AES.GCM.open(.init(combined: decoded.payload), using: symmetricKey)
						let str = String(data: decryptedData, encoding: .utf8)!

					} catch {
						// TODO: Handle error
					}
					sendDataIfNeeded()
				} catch {
					// TODO: Handle error
				}
			}
		}
	}
	
	func encryptData(data: Data, key: SymmetricKey) -> Data? {
		do {
			let sealedBox = try AES.GCM.seal(data, using: key)
			return sealedBox.combined
		} catch {
			return nil
		}
	}

	override func didFinishSendingDataWithSuccess() {
		context?.didFinishBinding()
	}
}
