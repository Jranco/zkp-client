//
//  BindingClient.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 08.03.24.
//

import Foundation
import CoreBluetooth
import Combine
import OSLog

extension Logger {
	/// Using your bundle identifier is a great way to ensure a unique identifier.
	private static var subsystem = Bundle.main.bundleIdentifier!
	static let deviceBinding = Logger(subsystem: subsystem, category: "device-binding")
}

class BindingClient: NSObject {

	// MARK: - Private properties

	/// A core-bluetooth peripheral manager instance.
	private var peripheralManager: CBPeripheralManager?
	/// Models the various states of the authenticator, obfuscating the underneath core-bluetooth states.
	@Published private(set) var state: State = .loading

	public static let characteristicUUID = CBUUID.init(nsuuid: UUID())
	public static let serviceUUID = CBUUID.init(nsuuid: UUID())
	public static let authenticatorUUID = CBUUID.init(nsuuid: UUID())
//	CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
	var transferCharacteristic: CBMutableCharacteristic?

	private var receivedData: Data = Data()
	private var shouldLoadMore: Bool = false
	
	// MARK: - Initialization

	override init() {
		super.init()
		self.peripheralManager = CBPeripheralManager(delegate: self,
													 queue: nil,
													 options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
		
	}

	// MARK: - Private methods

	private func setupAsPeripheral() {
		let transferCharacteristic = CBMutableCharacteristic(type: Self.characteristicUUID,
															 properties: [.notify, .write, .read],
															 value: nil,
															 permissions: [.readable, .writeable])
		let transferService = CBMutableService(type: Self.serviceUUID, primary: true)
		transferService.characteristics = [transferCharacteristic]
		peripheralManager?.add(transferService)
		self.transferCharacteristic = transferCharacteristic
	}

	private func startAdvertising() {
		let advertisementData: [String: Any] = [
			CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID]
//			CBAdvertisementDataLocalNameKey:  Self.authenticatorUUID
//			"MyCustomIdentifierKey": Self.authenticatorUUID
		]
		print("did start advertising: \(advertisementData)")
		Logger.deviceBinding.debug("did start advertising: \(advertisementData, privacy: .public)")
		peripheralManager?.startAdvertising(advertisementData)
	}
}

extension BindingClient {
	/// Models the various states of the authenticator, obfuscating the underneath core-bluetooth states.
	enum State {
		case loading
		case ready(serviceID: String, characteristicID: String)
		case unauthorizedOther
		case serviceOff
		case didConnectAuthenticator
		case other /// Try again later
	}
}

// MARK: - CBPeripheralManagerDelegate

extension BindingClient: CBPeripheralManagerDelegate {
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		switch peripheral.state {
		case .poweredOn:
			setupAsPeripheral()
			startAdvertising()
			state = .ready(serviceID: BindingClient.serviceUUID.uuidString, characteristicID: BindingClient.characteristicUUID.uuidString)
			Logger.deviceBinding.debug("State is ready with authID: \(BindingClient.authenticatorUUID.uuidString, privacy: .public) and serviceID: \(BindingClient.serviceUUID.uuidString, privacy: .public) and characteristic id: \(BindingClient.characteristicUUID.uuidString)")
		case .poweredOff:
			state = .serviceOff
		case .resetting:
			state = .other
		case .unauthorized:
			state = .unauthorizedOther
		default:
			state = .other
		}
	}
	
	internal func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
		
		Logger.deviceBinding.debug("did subsscribe to characteristic --- authenticator periperhal \(characteristic, privacy: .public), characteristic: \(characteristic, privacy: .public)")
	}
	
	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
		Logger.deviceBinding.debug("=----- peripheralManagerIsReady")

		guard shouldLoadMore == true else {
			return
		}
		
		let response2 = "aaand some more ...".data(using: .utf8)!
		let didSend2 = peripheral.updateValue(response2, for: transferCharacteristic!, onSubscribedCentrals: nil)
		
		if didSend2 {
			Logger.deviceBinding.debug("== ok did send repsonse")
		} else {
			Logger.deviceBinding.debug("== did fail to send repsonse")
		}
	}
	
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
		for aRequest in requests {
			guard let requestValue = aRequest.value,
				let stringFromData = String(data: requestValue, encoding: .utf8) else {
					continue
			}
			Logger.deviceBinding.debug("did receive value: \(stringFromData, privacy: .public)")
			
			if stringFromData != "EOF" {
				self.receivedData.append(requestValue)
				
			} else {
				
				do {
					let decoded = try JSONDecoder().decode(DeviceBindingMessageDTO.self, from: receivedData)
					let payloadStr = String(data: decoded.payload, encoding: .utf8)
					Logger.deviceBinding.debug("did decode msg type \(decoded.messageType.rawValue, privacy: .public), with payload \(payloadStr!, privacy: .public)")
					
				} catch {
					Logger.deviceBinding.debug("error decoding data : \(error.localizedDescription, privacy: .public)")
				}
				receivedData = Data()
				Logger.deviceBinding.debug("did receive EOF: \(stringFromData, privacy: .public)")
				let response = "Hey ho got your msg man".data(using: .utf8)!
				let didSend = peripheral.updateValue(response, for: transferCharacteristic!, onSubscribedCentrals: nil)
				
				if didSend {
					Logger.deviceBinding.debug("== ok did send repsonse")
				} else {
					Logger.deviceBinding.debug("== did fail to send repsonse")
				}
				
				let response2 = "ok that's it".data(using: .utf8)!
				let didSend2 = peripheral.updateValue(response2, for: transferCharacteristic!, onSubscribedCentrals: nil)
				
				if didSend2 {
					Logger.deviceBinding.debug("== ok did send repsonse2")
				} else {
					Logger.deviceBinding.debug("== did fail to send repsonse2")
				}
				self.peripheralManager?.respond(to: aRequest, withResult: .success)
				shouldLoadMore = true
			}
		}
	}
}
