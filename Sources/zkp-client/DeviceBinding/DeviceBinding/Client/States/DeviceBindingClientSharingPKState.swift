//
//  DeviceBindingClientSharingPKState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 17.03.24.
//

import Foundation
import CoreBluetooth
import OSLog

class DeviceBindingClientSharingPKState: DeviceBindingClientBaseState {
	
	var requestToShareKeyData = Data()
	var devicePK: Data

	private var responseDataWhatever: DeviceBindingMessageDTO {
		let data = "Candy topping candy canes gummi bears jelly beans jujubes jelly-o brownie gummi bears. Jelly-o bear claw fruitcake pudding ice cream caramels. Lemon drops brownie cheesecake liquorice jelly beans jelly tiramisu topping bear claw. Cookie fruitcake dessert macaroon ice cream caramels pudding pastry. Apple pie dessert powder pudding icing danish. Cotton candy macaroon candy marzipan tart cake bear claw. Pie tootsie roll dessert macaroon jelly-o biscuit. Macaroon gummies candy apple pie cheesecake powder pudding jelly beans. Topping soufflé dragée biscuit gingerbread liquorice jelly apple pie danish. Brownie pudding liquorice toffee croissant shortbread. Wafer bonbon liquorice jujubes candy ice cream soufflé fruitcake dragée. Cake marshmallow croissant tiramisu gingerbread icing. Macaroon sugar plum chocolate tiramisu jelly chupa chups gummies. Muffin caramels gummi bears marzipan candy. Macaroon chocolate bar chocolate cake topping cake. Carrot cake candy gingerbread gummi bears candy. Apple pie muffin bear claw cupcake halvah chocolate bar liquorice marshmallow icing. Lollipop toffee bear claw jelly-o croissant chocolate.".data(using: .utf8)!
		return DeviceBindingMessageDTO(messageType: .sendingPK, payload: data)
	}
	
	init(
		peripheralManager: CBPeripheralManager,
		transferCharacteristic: CBMutableCharacteristic?,
		connectedCentral: CBCentral?,
		devicePK: Data
	) {
		self.devicePK = devicePK
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
				self.requestToShareKeyData.append(requestValue)
				self.peripheralManager.respond(to: aRequest, withResult: .success)
			} else {
				self.peripheralManager.respond(to: aRequest, withResult: .success)
				do {
					let decoded = try JSONDecoder().decode(DeviceBindingMessageDTO.self, from: requestToShareKeyData)
					let payloadStr = String(data: decoded.payload, encoding: .utf8)
					Logger.deviceBinding.debug("did decode request to share key type \(decoded.messageType.rawValue, privacy: .public), with payload \(payloadStr!, privacy: .public)")
					Logger.deviceBinding.debug("did receive EOF: \(stringFromData, privacy: .public)")
					sendDataIfNeeded()
				} catch {
					Logger.deviceBinding.debug("error decoding data : \(error.localizedDescription, privacy: .public)")
				}
			}
		}
	}
	
	override func didFinishSendingDataWithSuccess() {
		///context?.changeState(state: DeviceBindingClientSharingPKState(peripheralManager: self.peripheralManager, transferCharacteristic: self.transferCharacteristic, connectedCentral: self.connectedCentral))
	}
}
