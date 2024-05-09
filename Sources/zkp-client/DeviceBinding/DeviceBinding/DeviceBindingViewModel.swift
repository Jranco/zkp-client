//
//  DeviceBindingViewModel.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 08.03.24.
//

import Foundation
import Combine

public protocol DeviceBindingDelegate: AnyObject {
	func deviceBindingDidSucceed()
	func deviceBindingDidFail(error: Error)
}

class DeviceBindingViewModel: ObservableObject {
	
	var newDeviceClient: BindingClient?
	@Published var state: State = .loading
	/// A set storing the `cancellable` subscriber instances.
	private var cancelBag: Set<AnyCancellable> = []
	private weak var delegate: DeviceBindingDelegate?
	private var devicePK: Data?
	private var zkpClient: ZKPClient?
	@Published var isLoading: Bool = true
	
	// MARK: - Initialization

	init(delegate: DeviceBindingDelegate?, client: ZKPClient) {
		self.delegate = delegate
		self.zkpClient = client
		Task {
			devicePK = try? await client.getDevicePublicKey()
			isLoading = false
		}
	}
	
	// MARK: - Public methods

	public func start() {
		guard let key = devicePK else {
			return
		}
		newDeviceClient = BindingClient(devicePK: key)
		setBinding()
	}

	// MARK: - Private methods

	private func setBinding() {
		newDeviceClient?.$state.sink { [weak self] in
			switch $0 {
			case .ready(let serviceID, let characteristicID):
				self?.state = .loaded(serviceID: serviceID, characteristicID: characteristicID)
				self?.delegate?.deviceBindingDidSucceed()
			case .didFinishBinding:
				if let devicePK = self?.devicePK {
					
					try? self?.zkpClient?.storeNewDevicePublicKey(key: devicePK)
				}
			default:
				self?.state = .fail(error: DeviceBindingError.failedToBind)
				self?.delegate?.deviceBindingDidFail(error: DeviceBindingError.failedToBind)
			}
		}
		.store(in: &cancelBag)
	}
}

enum DeviceBindingError: Error {
	case failedToBind
}

extension DeviceBindingViewModel {
	enum State {
		case loading
		case loaded(serviceID: String, characteristicID: String)
		case fail(error: Error)
	}
}
