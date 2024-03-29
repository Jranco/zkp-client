//
//  DeviceBindingAuthenticatorSynState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation
import CoreBluetooth
import CryptoKit

class DeviceBindingAuthenticatorSynState: DeviceBindingAuthenticatorBaseState {

	// MARK: - Private properties

	private var peripheral: CBPeripheral
	private var service: CBService
	private var characteristic: CBCharacteristic
	private var ackData: Data = Data()
	private let privateShareKey: P256.KeyAgreement.PrivateKey
	private var currentDate: Date
	private var clientPublicKey: Data?
	private var commonSymmetricKey: SymmetricKey? {
		guard let clientPublicKey = clientPublicKey else {
			print("Could not go to receiving public key. Missing authenticators public shared key")
			return nil
		}
		let key = try! P256.KeyAgreement.PublicKey(rawRepresentation: [UInt8](clientPublicKey))
		let sharedSecret = try! privateShareKey.sharedSecretFromKeyAgreement(with: key)

		let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
																	 salt: "hallo".data(using: .utf8)!,
																	 sharedInfo: Data(),
																	 outputByteCount: 32)
		return symmetricKey
	}

	init(
		peripheral: CBPeripheral,
		service: CBService,
		characteristic: CBCharacteristic
	) {
		self.peripheral = peripheral
		self.service = service
		self.characteristic = characteristic
		self.privateShareKey = P256.KeyAgreement.PrivateKey()
		self.currentDate = Date()
	}

	override func start() {
//		let payload = "Candy pastry pastry cheesecake jujubes jelly beans jelly beans cake. Pie cupcake cupcake cake lollipop oat cake liquorice chupa chups pastry. Lemon drops muffin fruitcake sugar plum oat cake tiramisu lollipop lemon drops icing. Jujubes cake marzipan macaroon candy canes brownie apple pie cookie. Donut powder lollipop croissant caramels cake marzipan. Gummies croissant toffee powder chocolate bar ice cream dragée chocolate bar. Jelly beans macaroon halvah jelly beans cake toffee chupa chups sesame snaps. Jelly-o powder pastry powder apple pie sweet roll candy candy. Caramels cupcake carrot cake brownie pastry. Ice cream marzipan apple pie powder sesame snaps wafer. Soufflé wafer wafer pastry caramels danish tiramisu jelly-o gummies. Chocolate bar bonbon sweet muffin caramels. Sesame snaps sweet roll dessert marzipan gingerbread pie. Muffin sweet roll oat cake apple pie lemon drops jujubes. Bear claw wafer ice cream gummi bears tiramisu cheesecake sesame snaps fruitcake jelly beans. Halvah lollipop chocolate cake brownie tiramisu halvah. Gingerbread candy croissant tiramisu soufflé cupcake sugar plum. Pie bonbon marshmallow icing bear claw topping icing sesame snaps jelly-o."
		
		let payload = DeviceBindingSynPayload(timestamp: currentDate.timeIntervalSince1970, publicKey: privateShareKey.publicKey.rawRepresentation)
		let payloadEncoded = try! JSONEncoder().encode(payload)
		let dto = DeviceBindingMessageDTO(messageType: .syn, payload: payloadEncoded)
		self.sendDTO(dto, toPeripheral: peripheral, forCharacteristic: characteristic)
	}

	override func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		print("did write value with error: \(error)")
		if let error = error {
			context?.changeState(state: DeviceBindingAuthenticatorSynFailedState(error: SynError.failedToSendData(underlyingError: error)))
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
				print("- did receive ack: \(decoded)")
				
				if
					let decoded = try? JSONDecoder().decode(DeviceBindingAckPayload.self, from: decoded.payload),
					decoded.timestamp == self.currentDate.timeIntervalSince1970 + 1
				{
					self.clientPublicKey = decoded.publicKey

					context?.changeState(state: DeviceBindingAuthenticatorReceivingPKState(peripheral: self.peripheral, service: self.service, characteristic: self.characteristic, clientAckResponse: decoded, commonSymmetricKey: commonSymmetricKey!))
				} else {
					context?.changeState(state: DeviceBindingAuthenticatorSynFailedState(error: SynError.receivedWrongAckNumber))
				}

			} catch {
				print("error acking: \(error)")
			}
		}
	}
}

private enum SynError: Error {
	case failedToSendData(underlyingError: Error)
	case receivedWrongAckNumber
}
