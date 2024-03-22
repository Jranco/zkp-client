//
//  DeviceBindingAuthenticatorReceivingPKState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 17.03.24.
//

import Foundation
import CoreBluetooth

class DeviceBindingAuthenticatorReceivingPKState: DeviceBindingAuthenticatorBaseState {
	
	private var peripheral: CBPeripheral
	private var service: CBService
	private var characteristic: CBCharacteristic
	private var publicKey: Data = Data()

	init(
		peripheral: CBPeripheral,
		service: CBService,
		characteristic: CBCharacteristic
	) {
		self.peripheral = peripheral
		self.service = service
		self.characteristic = characteristic
	}
	
	override func start() {
		let payload = "Lollipop tart powder gingerbread liquorice gummi bears sweet toffee cake. Lemon drops fruitcake pastry candy chocolate carrot cake topping cotton candy sugar plum. Pastry dessert cotton candy sweet roll chocolate cake cupcake topping. Sweet dragée caramels gummies cake. Ice cream dragée cupcake wafer cotton candy caramels. Brownie cheesecake gummi bears chocolate jelly-o. Chocolate cake toffee marshmallow cake jelly beans topping jujubes tart dessert. Bonbon chocolate halvah jelly beans topping dessert soufflé. Shortbread sweet brownie sweet chupa chups. Pie chocolate lollipop cotton candy carrot cake pudding apple pie pastry topping. Cake oat cake marshmallow chocolate bear claw bear claw. Halvah fruitcake liquorice cupcake apple pie shortbread lemon drops apple pie apple pie. Gingerbread sugar plum chupa chups gummi bears muffin halvah tootsie roll. Bonbon wafer pastry sugar plum cotton candy shortbread croissant marzipan tart. Cupcake gummi bears jelly tootsie roll chupa chups toffee jelly fruitcake lemon drops. Powder liquorice gummies tiramisu gummi bears. Chupa chups toffee oat cake shortbread jujubes icing donut toffee. Caramels sesame snaps soufflé jelly chocolate. Chocolate cake sweet roll powder pudding donut."
		
		let dto = DeviceBindingMessageDTO(messageType: .waitingForPK, payload: payload.data(using: .utf8)!)
		self.sendDTO(dto, toPeripheral: peripheral, forCharacteristic: characteristic)
		print("- sending request to get pk")
	}
	
	override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		
		if let error = error {
			print("Error syn - didUpdateValueFor: \(error.localizedDescription)")
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
				let payloadStr = String(data: decoded.payload, encoding: .utf8)
				let sendData = String(data: decoded.payload, encoding: .utf8)
				print("- did decode public key: \(payloadStr)")
//				context?.changeState(state: DeviceBindingAuthenticatorReceivingPKState(peripheral: self.peripheral, service: self.service, characteristic: self.characteristic))
				// TODO: Go to OTP sending state
			} catch {
				print("error acking: \(error)")
			}
		}
	}
}
