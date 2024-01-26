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
	/// Publisher emitting new messages received by an open web-socket connection.
	var incomingMessagePublisher: AnyPublisher<String, Error> { get }

	/// Triggers a handshake establishing the web-socket connection.
	func start()
	/// Terminates the open web-socket connection if it exists.
	func stop()
	/// Sends a `string` message through the open web-socket connection.
	func sendMessage(message: String)
	/// Sends a `binary` message through the open web-socket connection.
	func sendMessage(message: Data)
}
