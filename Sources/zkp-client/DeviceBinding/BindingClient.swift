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

class BindingClient: NSObject, DeviceBindingClientStateContextProtocol {
	
	// MARK: - Private properties

	var devicePK: Data
	/// A core-bluetooth peripheral manager instance.
	private var peripheralManager: CBPeripheralManager!
	/// Models the various states of the authenticator, obfuscating the underneath core-bluetooth states.
	@Published private(set) var state: State = .loading

	public static let characteristicUUID = CBUUID.init(nsuuid: UUID())
	public static let serviceUUID = CBUUID.init(nsuuid: UUID())
	public static let authenticatorUUID = CBUUID.init(nsuuid: UUID())
//	CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
	var transferCharacteristic: CBMutableCharacteristic?
	
	private var receivedData: Data = Data()
	private var shouldLoadMore: Bool = false
	var currentSearchState: DeviceBindingClientStateProtocol = DeviceBindingClientSynPendingState(peripheralManager: .init(), transferCharacteristic: nil, connectedCentral: nil)

	// MARK: - Initialization

	init(devicePK: Data) {
		self.devicePK = devicePK
		super.init()
		self.peripheralManager = CBPeripheralManager(delegate: self,
													 queue: nil,
													 options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
		self.currentSearchState = DeviceBindingClientSynPendingState(peripheralManager: peripheralManager, transferCharacteristic: nil, connectedCentral: nil)
	}

	// MARK: - Private methods

	private func setupAsPeripheral() {
		let transferCharacteristic = CBMutableCharacteristic(type: Self.characteristicUUID,
															 properties: [.notify, .write, .read],
															 value: nil,
															 permissions: [.readable, .writeable])
		let transferService = CBMutableService(type: Self.serviceUUID, primary: true)
		transferService.characteristics = [transferCharacteristic]
		peripheralManager.add(transferService)
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
		peripheralManager.startAdvertising(advertisementData)
	}

	// MARK: - DeviceBindingClientStateContextProtocol
	
	func changeState(state: DeviceBindingClientStateProtocol) {
		self.currentSearchState = state
		self.currentSearchState.context = self
		state.start()
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
		changeState(state: DeviceBindingClientAckState(peripheralManager: self.peripheralManager, transferCharacteristic: self.transferCharacteristic, connectedCentral: central))
	}

	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
		Logger.deviceBinding.debug("=----- peripheralManagerIsReady")
		self.currentSearchState.peripheralManagerIsReady(toUpdateSubscribers: peripheral)
	}
	
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
		self.currentSearchState.peripheralManager(peripheral, didReceiveWrite: requests)
	}
}
