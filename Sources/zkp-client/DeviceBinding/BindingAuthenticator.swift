//
//  BindingAuthenticator.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 08.03.24.
//

import Foundation

import Foundation
import CoreBluetooth
import Combine

public class BindingAuthenticator: NSObject, DeviceBindingAuthenticatorStateContextProtocol {
	private var centralManager: CBCentralManager?
	private var serviceID: String
	private var characteristicID: String
	private var discoveredPeripheral: CBPeripheral?
	private var transferCharacteristic: CBCharacteristic?
	var currentSearchState: DeviceBindingAuthenticatorStateProtocol = DeviceBindingAuthenticatorDiscoveringState()
	
	var client: ZKPClient?

	public init(
		serviceID: String,
		characteristicID: String,
		client: ZKPClient?
	) {
		self.serviceID = serviceID
		self.characteristicID = characteristicID
		self.client = client
		super.init()
		self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
	}


	private func retrievePeripheral() {
		centralManager?.scanForPeripherals(withServices: [.init(string: serviceID)],
											   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
	}

	// MARK: - DeviceBindingAuthenticatorStateContextProtocol

	func changeState(state: DeviceBindingAuthenticatorStateProtocol) {
		self.currentSearchState = state
		self.currentSearchState.context = self
		state.start()
	}
}

extension BindingAuthenticator: CBCentralManagerDelegate {
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
		case .poweredOn:
			retrievePeripheral()
		case .poweredOff:
			return
		case .resetting:
			return
		case .unauthorized:
			return
		case .unknown:
			return
		case .unsupported:
			return
		@unknown default:
			return
		}
	}

	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		
		if 
			let seviceIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
			seviceIDs.count == 1,
			let identifier = seviceIDs.first(where: {
				$0.uuidString == self.serviceID
			}),
			discoveredPeripheral != peripheral
		{
			discoveredPeripheral = peripheral
			centralManager?.connect(peripheral)
		}
	}

	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		// TODO: Handle error
	}

	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		centralManager?.stopScan()
		peripheral.delegate = self
		peripheral.discoverServices([CBUUID(string: serviceID)])
	}
}

extension BindingAuthenticator: CBPeripheralDelegate {
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let peripheralServices = peripheral.services else { return }
		let service = peripheralServices.first {
			$0.uuid.uuidString == self.serviceID
		}

		if let service = service {
			peripheral.discoverCharacteristics([CBUUID(string: self.characteristicID)], for: service)
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let serviceCharacteristics = service.characteristics else { return }
		for characteristic in serviceCharacteristics where characteristic.uuid.uuidString == self.characteristicID {
			transferCharacteristic = characteristic
			peripheral.setNotifyValue(true, for: characteristic)
			changeState(state: DeviceBindingAuthenticatorSynState(peripheral: peripheral, service: service, characteristic: characteristic))
		}
	}

	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		currentSearchState.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
	}
	
	private func sendData(_ data: Data, toPeripheral peripheral: CBPeripheral, forCharacteristic characteristic: CBCharacteristic) {
		let mtu = peripheral.maximumWriteValueLength(for: .withResponse) // Get the negotiated MTU
		
		// Split the data into chunks based on the MTU size
		var offset = 0
		while offset < data.count {
			let chunkSize = min(mtu, data.count - offset)
			let chunk = data.subdata(in: offset..<offset + chunkSize)
			peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
			offset += chunkSize
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		currentSearchState.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
	}
}

struct DeviceBindingMessageDTO: Codable {
	var messageType: MessageType
	var payload: Data
}

extension DeviceBindingMessageDTO {
	enum MessageType: String, Codable, CaseIterable {
		case syn
		case ack
		case waitingForPK
		case sendingPK
	}
}

struct DeviceBindingSynPayload: Codable {
	var timestamp: TimeInterval
	var publicKey: Data
}

struct DeviceBindingAckPayload: Codable {
	var timestamp: TimeInterval
	var publicKey: Data
}
