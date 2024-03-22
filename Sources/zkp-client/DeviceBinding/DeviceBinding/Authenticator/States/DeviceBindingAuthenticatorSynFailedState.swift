//
//  DeviceBindingAuthenticatorSynFailedState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation

class DeviceBindingAuthenticatorSynFailedState: DeviceBindingAuthenticatorBaseState {
	var error: Error
	
	init(error: Error) {
		self.error = error
	}
}
