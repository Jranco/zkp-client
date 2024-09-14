//
//  DeviceBindingAuthenticatorReceivingPKState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 17.03.24.
//

import Foundation
import CoreBluetooth
import CryptoKit

class DeviceBindingAuthenticatorReceivingPKState: DeviceBindingAuthenticatorBaseState {

	private var peripheral: CBPeripheral
	private var service: CBService
	private var characteristic: CBCharacteristic
	private var publicKey: Data = Data()

	private var clientAckResponse: DeviceBindingAckPayload
	private var commonSymmetricKey: SymmetricKey
	
	init(
		peripheral: CBPeripheral,
		service: CBService,
		characteristic: CBCharacteristic,
		clientAckResponse: DeviceBindingAckPayload,
		commonSymmetricKey: SymmetricKey
	) {
		self.peripheral = peripheral
		self.service = service
		self.characteristic = characteristic
		self.clientAckResponse = clientAckResponse
		self.commonSymmetricKey = commonSymmetricKey
	}

	override func start() {
		let payload = "Reqeust zkp public key"
		let encryptedPayload = self.encryptData(data: payload.data(using: .utf8)!, key: commonSymmetricKey)
		let dto = DeviceBindingMessageDTO(messageType: .waitingForPK, payload: encryptedPayload!)
		self.sendDTO(dto, toPeripheral: peripheral, forCharacteristic: characteristic)
	}
	
	override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
	
		if let error = error {
			// TODO: Handle error
			return
		}

		guard
			let data = characteristic.value,
			let stringFromData = String(data: data, encoding: .utf8)
		else {
			return
		}

		if stringFromData != "EOF" {
			self.publicKey.append(data)
		} else {
			do {
				let decoded = try JSONDecoder().decode(DeviceBindingMessageDTO.self, from: publicKey)
				let zkpClientKey = decoded.payload
				let decryptedData = try AES.GCM.open(.init(combined: zkpClientKey), using: commonSymmetricKey)
				Task {
					do {
						try await self.context?.client?.sendDeviceBinding(payload: "bind new device".data(using: .utf8)!, otherDeviceKey: decryptedData)
					} catch {
					}
				}
			} catch {
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
}
