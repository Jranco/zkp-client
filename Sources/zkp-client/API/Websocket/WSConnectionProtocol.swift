//
//  WSConnectionProtocol.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import Combine
import Foundation

/// A protocol describing the requirements to establish and maintain a `web-socket`connection.
protocol WSConnectionProtocol {
	associatedtype PayloadType: Codable

	/// Publisher emitting new messages received by an open web-socket connection.
	var incomingMessagePublisher: AnyPublisher<PayloadType, Error> { get }
	/// Publisher emitting state updates received of an open web-socket connection.
	var statePublisher: AnyPublisher<WSConnectionState, Never> { get }
	/// WebSocket connection state with regard to its lifecycle.
	var state: WSConnectionState { get }
	/// Triggers a handshake establishing the web-socket connection.
	func start()
	/// Terminates the open web-socket connection if it exists.
	func stop()
	/// Sends a `string` message through the open web-socket connection.
	func sendMessage(message: String)
	/// Sends a `binary` message through the open web-socket connection.
	func sendMessage(message: Data)
}
