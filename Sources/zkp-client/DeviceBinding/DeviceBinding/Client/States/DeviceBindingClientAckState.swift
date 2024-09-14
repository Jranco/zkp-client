//
//  DeviceBindingClientAckState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation
import CoreBluetooth
import OSLog
import CryptoKit

class DeviceBindingClientAckState: DeviceBindingClientBaseState {
	
	private var synData = Data()
	private let privateShareKey: P256.KeyAgreement.PrivateKey
	private var authenticatorsPublicKey: Data?
	private var commonSymmetricKey: SymmetricKey? {
		guard let authenticatorsPublicKey = authenticatorsPublicKey else {
			return nil
		}
		let key = try! P256.KeyAgreement.PublicKey(rawRepresentation: [UInt8](authenticatorsPublicKey))
		let sharedSecret = try! privateShareKey.sharedSecretFromKeyAgreement(with: key)

		let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
																	 salt: "hallo".data(using: .utf8)!,
																	 sharedInfo: Data(),
																	 outputByteCount: 32)
		return symmetricKey
	}

	private var responseDataWhatever: DeviceBindingMessageDTO {
		let data = "some-payload".data(using: .utf8)!
		return DeviceBindingMessageDTO(messageType: .ack, payload: data)
	}
	
	override init(
		peripheralManager: CBPeripheralManager,
		transferCharacteristic: CBMutableCharacteristic?,
		connectedCentral: CBCentral?
	) {
		self.privateShareKey = P256.KeyAgreement.PrivateKey()
		super.init(peripheralManager: peripheralManager, transferCharacteristic: transferCharacteristic, connectedCentral: connectedCentral)
		self.responseData = try! JSONEncoder().encode(responseDataWhatever)
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
					
					if let decodedSyn = try? JSONDecoder().decode(DeviceBindingSynPayload.self, from: decoded.payload) {
						self.authenticatorsPublicKey = decodedSyn.publicKey
						let ackPayloadData = DeviceBindingAckPayload(timestamp: decodedSyn.timestamp+1, publicKey: self.privateShareKey.publicKey.rawRepresentation)
						let ackPaylodEncded = try! JSONEncoder().encode(ackPayloadData)
						let responseDTO = DeviceBindingMessageDTO(messageType: .ack, payload: ackPaylodEncded)
						self.responseData = try! JSONEncoder().encode(responseDTO)
						sendDataIfNeeded()
					} else {
						// TODO: go to erroneous state
						Logger.deviceBinding.debug("error decoding syn from sender")
					}
				} catch {
					Logger.deviceBinding.debug("error decoding data : \(error.localizedDescription, privacy: .public)")
				}
			}
		}
	}

	override func didFinishSendingDataWithSuccess() {
		guard let commonSymmetricKey = commonSymmetricKey else {
			Logger.deviceBinding.debug("Could not go to receiving public key. Missing authenticator's public shared key")
			return
		}
		let newState = DeviceBindingClientSharingPKState(
			peripheralManager: peripheralManager,
			transferCharacteristic: transferCharacteristic,
			connectedCentral: connectedCentral,
			devicePK: context!.devicePK, 
			symmetricKey: commonSymmetricKey)
		context?.changeState(state: newState)
	}
}
