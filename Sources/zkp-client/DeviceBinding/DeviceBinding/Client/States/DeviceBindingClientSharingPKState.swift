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
			Logger.deviceBinding.debug("Client sending zkp PK: \(String(data: self.context!.devicePK, encoding: .utf8)!, privacy: .public)")
			let dto = DeviceBindingMessageDTO(messageType: .sendingPK, payload: encryptedZKPKey!)
			self.responseData = try! JSONEncoder().encode(dto)
		}
	}

	private var responseDataWhatever: DeviceBindingMessageDTO {
		let data = "Candy topping candy canes gummi bears jelly beans jujubes jelly-o brownie gummi bears. Jelly-o bear claw fruitcake pudding ice cream caramels. Lemon drops brownie cheesecake liquorice jelly beans jelly tiramisu topping bear claw. Cookie fruitcake dessert macaroon ice cream caramels pudding pastry. Apple pie dessert powder pudding icing danish. Cotton candy macaroon candy marzipan tart cake bear claw. Pie tootsie roll dessert macaroon jelly-o biscuit. Macaroon gummies candy apple pie cheesecake powder pudding jelly beans. Topping soufflé dragée biscuit gingerbread liquorice jelly apple pie danish. Brownie pudding liquorice toffee croissant shortbread. Wafer bonbon liquorice jujubes candy ice cream soufflé fruitcake dragée. Cake marshmallow croissant tiramisu gingerbread icing. Macaroon sugar plum chocolate tiramisu jelly chupa chups gummies. Muffin caramels gummi bears marzipan candy. Macaroon chocolate bar chocolate cake topping cake. Carrot cake candy gingerbread gummi bears candy. Apple pie muffin bear claw cupcake halvah chocolate bar liquorice marshmallow icing. Lollipop toffee bear claw jelly-o croissant chocolate.".data(using: .utf8)!
		return DeviceBindingMessageDTO(messageType: .sendingPK, payload: data)
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
//		self.responseData = try! JSONEncoder().encode(responseDataWhatever)
//		let encryptedZKPKey = self.encryptData(data: self.context!.devicePK, key: symmetricKey)
//		Logger.deviceBinding.debug("Client sending zkp PK: \(String(data: self.context!.devicePK, encoding: .utf8)!, privacy: .public)")
//		let dto = DeviceBindingMessageDTO(messageType: .sendingPK, payload: encryptedZKPKey!)
//		self.responseData = try! JSONEncoder().encode(dto)
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
				self.requestToShareKeyData.append(requestValue)
				self.peripheralManager.respond(to: aRequest, withResult: .success)
			} else {
				self.peripheralManager.respond(to: aRequest, withResult: .success)
				do {
					let decoded = try JSONDecoder().decode(DeviceBindingMessageDTO.self, from: requestToShareKeyData)
					let payloadStr = String(data: decoded.payload, encoding: .utf8)
					
					/////
					///
					do {
						let decryptedData = try AES.GCM.open(.init(combined: decoded.payload), using: symmetricKey)
						let str = String(data: decryptedData, encoding: .utf8)!
						Logger.deviceBinding.debug("decrypted request to share zkp key \(str, privacy: .public)")

						///Logger.deviceBinding.debug("did decode request to share zkp public ky \(String(data: decryptedData!, encoding: .utf8), privacy: .public), with payload \(payloadStr!, privacy: .public)")

					} catch {
						Logger.deviceBinding.debug("error decrypting request to share zkp key")
					}
					////
					sendDataIfNeeded()
				} catch {
					Logger.deviceBinding.debug("error decoding data : \(error.localizedDescription, privacy: .public)")
				}
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

	override func didFinishSendingDataWithSuccess() {
		Logger.deviceBinding.debug("did finish sending zkp public key...")
	}
}
