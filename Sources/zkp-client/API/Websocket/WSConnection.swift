//
//  WSConnection.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import Combine
import Foundation

/// Establishes and maintains a `web-socket`connection sending the initially requested payload
/// and identifying the device based on the given secrets.
final class WSConnection: WSConnectionProtocol {

	// MARK: - WSConnectionProtocol

	var incomingMessagePublisher: AnyPublisher<String, Error> {
		subject.eraseToAnyPublisher()
	}

	// MARK: - Private properties

	private var webSocketTask: URLSessionWebSocketTask
	private var subject = PassthroughSubject<String, Error>()
	private var config: WSConnectionConfig
	
	// MARK: - Initialization
	
	init(config: WSConnectionConfig) throws {
		self.config = config
		let urlSession = URLSession(configuration: .default)
		/// Continue only if the url is valid.
		/// Throw respective error in other case to inform the caller injecting the configuration.
		guard let url = URL(string: config.path) else {
			throw WSConnectionError.invalidURL
		}

		self.webSocketTask = urlSession.webSocketTask(with: url)
		setupBindings()
	}

	// MARK: - WSConnectionProtocol

	func start() {
		webSocketTask.resume()
	}

	func stop() {
		webSocketTask.cancel(with: .goingAway, reason: nil)
	}

	func sendMessage(message: String) {
		webSocketTask.send(.string(message), completionHandler: { _ in
		})
	}

	func sendMessage(message: Data) {
		webSocketTask.send(.data(message), completionHandler: { _ in
		})
	}

	// MARK: - Private methods

	func setupBindings() {
		webSocketTask.receive { [weak self] result in
			switch result {
			case .success(let success):
				switch success {
				case .data(_): break
				case .string(let responseMessage):
					self?.subject.send(responseMessage)
				@unknown default: break
				}
			case .failure(let failure):
				print("failure: \(failure)")
				self?.subject.send(completion: .failure(failure))
			}
			// TODO: check if the following redeclaration is needed
//			self?.setupBindings()
		}
	}
}

extension WSConnection {
	/// Errors thrown by the `WSConnection`.
	enum WSConnectionError: LocalizedError {
		case invalidURL
		
		var errorDescription: String? {
			switch self {
			case .invalidURL:
				return "Could not create the target url from the given config's path"
			}
		}
	}
}
