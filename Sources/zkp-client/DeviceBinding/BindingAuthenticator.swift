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
	
	public init(serviceID: String, characteristicID: String) {
		self.serviceID = serviceID
		self.characteristicID = characteristicID
		super.init()
		self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
	}

	/*
	 * We will first check if we are already connected to our counterpart
	 * Otherwise, scan for peripherals - specifically for our service's 128bit CBUUID
	 */
	private func retrievePeripheral() {
		
//		let connectedPeripherals: [CBPeripheral] = (centralManager.retrieveConnectedPeripherals(withServices: [TransferService.serviceUUID]))
//		
//		os_log("Found connected Peripherals with transfer service: %@", connectedPeripherals)
//		
//		if let connectedPeripheral = connectedPeripherals.last {
//			os_log("Connecting to peripheral %@", connectedPeripheral)
//			self.discoveredPeripheral = connectedPeripheral
//			centralManager.connect(connectedPeripheral, options: nil)
//		} else {
			// We were not connected to our counterpart, so start scanning
		centralManager?.scanForPeripherals(withServices: [.init(string: serviceID)],
											   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
//		}
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
			print("CBManager os ON")
			retrievePeripheral()
		case .poweredOff:
			print("CBManager is not powered on")
			// In a real app, you'd deal with all the states accordingly
			return
		case .resetting:
			print("CBManager is resetting")
			// In a real app, you'd deal with all the states accordingly
			return
		case .unauthorized:
				switch central.authorization {
				case .denied:
					print("You are not authorized to use Bluetooth")
				case .restricted:
					print("Bluetooth is restricted")
				default:
					print("Unexpected authorization")
				}
			return
		case .unknown:
			print("CBManager state is unknown")
			// In a real app, you'd deal with all the states accordingly
			return
		case .unsupported:
			print("Bluetooth is not supported on this device")
			// In a real app, you'd deal with all the states accordingly
			return
		@unknown default:
			print("A previously unknown central manager state occurred")
			// In a real app, you'd deal with yet unknown cases that might occur in the future
			return
		}
	}

	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//		print("\n!! did discover peripheral with advertisement data: \(advertisementData)\n")
		
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
			print("Whorayy did discover: \(identifier)")
		}
	}

	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		print("--- did fail to connect: \(error)")
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
		// Again, we loop through the array, just in case and check if it's the right one
		guard let serviceCharacteristics = service.characteristics else { return }
		for characteristic in serviceCharacteristics where characteristic.uuid.uuidString == self.characteristicID {
			// If it is, subscribe to it
			transferCharacteristic = characteristic
			peripheral.setNotifyValue(true, for: characteristic)
			
			let data: Data! = "Candy pastry pastry cheesecake jujubes jelly beans jelly beans cake. Pie cupcake cupcake cake lollipop oat cake liquorice chupa chups pastry. Lemon drops muffin fruitcake sugar plum oat cake tiramisu lollipop lemon drops icing. Jujubes cake marzipan macaroon candy canes brownie apple pie cookie. Donut powder lollipop croissant caramels cake marzipan. Gummies croissant toffee powder chocolate bar ice cream dragée chocolate bar. Jelly beans macaroon halvah jelly beans cake toffee chupa chups sesame snaps. Jelly-o powder pastry powder apple pie sweet roll candy candy. Caramels cupcake carrot cake brownie pastry. Ice cream marzipan apple pie powder sesame snaps wafer. Soufflé wafer wafer pastry caramels danish tiramisu jelly-o gummies. Chocolate bar bonbon sweet muffin caramels. Sesame snaps sweet roll dessert marzipan gingerbread pie. Muffin sweet roll oat cake apple pie lemon drops jujubes. Bear claw wafer ice cream gummi bears tiramisu cheesecake sesame snaps fruitcake jelly beans. Halvah lollipop chocolate cake brownie tiramisu halvah. Gingerbread candy croissant tiramisu soufflé cupcake sugar plum. Pie bonbon marshmallow icing bear claw topping icing sesame snaps jelly-o. EOF -".data(using: .utf8)
//			let data: Data! = "Hello, playground".data(using: .utf8)
			let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
			print("--- mtu: \(mtu)")

			var rawPacket = [UInt8]()
			
			let bytesToCopy: size_t = min(mtu, data.count)
			data.copyBytes(to: &rawPacket, count: bytesToCopy)
			let packetData = Data(bytes: &rawPacket, count: bytesToCopy)
			
			let stringFromData = String(data: packetData, encoding: .utf8)
			
			var sendDataIndex = 0
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
		case otp
		case waitingForPK
		case sendingPK
	}
}
