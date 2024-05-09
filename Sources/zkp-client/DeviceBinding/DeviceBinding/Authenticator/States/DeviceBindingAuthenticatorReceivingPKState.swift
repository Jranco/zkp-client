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
	var client: ZKPClient?
	
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
		let payload = "Give me your zkp public key sucker"
		let encryptedPayload = self.encryptData(data: payload.data(using: .utf8)!, key: commonSymmetricKey)
		let dto = DeviceBindingMessageDTO(messageType: .waitingForPK, payload: encryptedPayload!)
		self.sendDTO(dto, toPeripheral: peripheral, forCharacteristic: characteristic)
	}
	
	override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		
		if let error = error {
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
				let decryptedZKPPublicKey = String(data: decryptedData, encoding: .utf8)!
				
				self.client = try! ZKPClient(flavor: .fiatShamir(config: .init(coprimeWidth: 256)),
											  apiConfig: APIConfiguration(baseWSURL: "ws://192.168.178.52:8013", baseHTTPURL: "http://192.168.178.52:8013"),
											   userID: "tom54")
				Task {
					do {
						try await self.client?.sendDeviceBinding(payload: "bind new device".data(using: .utf8)!, otherDeviceKey: decryptedData)
					} catch {
					}
				}
				
//				context?.changeState(state: DeviceBindingAuthenticatorReceivingPKState(peripheral: self.peripheral, service: self.service, characteristic: self.characteristic))
				// TODO: Go to OTP sending state
			} catch {
			}
		}
	}
	
	func encryptData(data: Data, key: SymmetricKey) -> Data? {
		do {
			let sealedBox = try AES.GCM.seal(data, using: key)
			return sealedBox.combined
		} catch {
			print("Encryption failed with error: \(error)")
			return nil
		}
	}
}
