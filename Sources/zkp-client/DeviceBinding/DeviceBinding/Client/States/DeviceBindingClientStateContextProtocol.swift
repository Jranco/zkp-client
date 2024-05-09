//
//  DeviceBindingClientStateContextProtocol.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 16.03.24.
//

import Foundation

protocol DeviceBindingClientStateContextProtocol: AnyObject {
	var devicePK: Data { get }
	var currentSearchState: DeviceBindingClientStateProtocol { get set }
	func changeState(state: DeviceBindingClientStateProtocol)
	func didFinishBinding()
}
