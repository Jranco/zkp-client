//
//  DeviceBindingAuthenticatorSynState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation
import CoreBluetooth

class DeviceBindingAuthenticatorSynState: DeviceBindingAuthenticatorBaseState {

	// MARK: - Private properties

	private var peripheral: CBPeripheral
	private var service: CBService
	private var characteristic: CBCharacteristic
	private var ackData: Data = Data()

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
		let payload = "Candy pastry pastry cheesecake jujubes jelly beans jelly beans cake. Pie cupcake cupcake cake lollipop oat cake liquorice chupa chups pastry. Lemon drops muffin fruitcake sugar plum oat cake tiramisu lollipop lemon drops icing. Jujubes cake marzipan macaroon candy canes brownie apple pie cookie. Donut powder lollipop croissant caramels cake marzipan. Gummies croissant toffee powder chocolate bar ice cream dragée chocolate bar. Jelly beans macaroon halvah jelly beans cake toffee chupa chups sesame snaps. Jelly-o powder pastry powder apple pie sweet roll candy candy. Caramels cupcake carrot cake brownie pastry. Ice cream marzipan apple pie powder sesame snaps wafer. Soufflé wafer wafer pastry caramels danish tiramisu jelly-o gummies. Chocolate bar bonbon sweet muffin caramels. Sesame snaps sweet roll dessert marzipan gingerbread pie. Muffin sweet roll oat cake apple pie lemon drops jujubes. Bear claw wafer ice cream gummi bears tiramisu cheesecake sesame snaps fruitcake jelly beans. Halvah lollipop chocolate cake brownie tiramisu halvah. Gingerbread candy croissant tiramisu soufflé cupcake sugar plum. Pie bonbon marshmallow icing bear claw topping icing sesame snaps jelly-o."
		
		let dto = DeviceBindingMessageDTO(messageType: .syn, payload: payload.data(using: .utf8)!)
		self.sendDTO(dto, toPeripheral: peripheral, forCharacteristic: characteristic)
	}

	override func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		print("did write value with error: \(error)")
		if let error = error {
			context?.changeState(state: DeviceBindingAuthenticatorSynFailedState(error: error))
			return
		}

		guard let value = characteristic.value else {
			return
		}
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
			self.ackData.append(data)
		} else {
			do {
				let decoded = try JSONDecoder().decode(DeviceBindingMessageDTO.self, from: ackData)
				let payloadStr = String(data: decoded.payload, encoding: .utf8)
				let sendData = String(data: decoded.payload, encoding: .utf8)
				print("- did decode ack: \(payloadStr)")
				context?.changeState(state: DeviceBindingAuthenticatorReceivingPKState(peripheral: self.peripheral, service: self.service, characteristic: self.characteristic))
				// TODO: Go to OTP sending state
			} catch {
				print("error acking: \(error)")
			}
		}
	}
}
