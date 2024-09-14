//
//  DeviceBindingAuthenticatorStateContextProtocol.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation

protocol DeviceBindingAuthenticatorStateContextProtocol: AnyObject {
	var client: ZKPClient? { get }
	var currentSearchState: DeviceBindingAuthenticatorStateProtocol { get set }
	func changeState(state: DeviceBindingAuthenticatorStateProtocol)
}
