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

	// MARK: - Initialization

	init(delegate: DeviceBindingDelegate?) {
		self.delegate = delegate
	}
	
	// MARK: - Public methods

	public func start() {
		newDeviceClient = BindingClient()
		setBinding()
	}

	// MARK: - Private methods

	private func setBinding() {
		newDeviceClient?.$state.sink { [weak self] in
			switch $0 {
			case .ready(let serviceID, let characteristicID):
				self?.state = .loaded(serviceID: serviceID, characteristicID: characteristicID)
				self?.delegate?.deviceBindingDidSucceed()
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
