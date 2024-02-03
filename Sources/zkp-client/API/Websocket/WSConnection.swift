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
final class WSConnection<ResponsePayload: Codable>: WSConnectionProtocol {

	// MARK: - WSConnectionProtocol

	var incomingMessagePublisher: AnyPublisher<ResponsePayload, Error> {
		messageSubject.eraseToAnyPublisher()
	}

	var statePublisher: AnyPublisher<WSConnectionState, Never> {
		$state.eraseToAnyPublisher()
	}

	@Published private(set) var state: WSConnectionState

	// MARK: - Private properties

	private var webSocketTask: URLSessionWebSocketTask
	private var messageSubject = PassthroughSubject<ResponsePayload, Error>()
	private var config: any WSConnectionConfig

	// MARK: - Initialization
	
	init(config: any WSConnectionConfig) throws {
		self.config = config
		self.state = .idle
		let urlSession = URLSession(configuration: .default)
		/// Continue only if the url is valid.
		/// Throw respective error in other case to inform the caller injecting the configuration.
		guard let url = URL(string: config.base+config.path) else {
			throw WSConnectionError.invalidURL
		}

		self.webSocketTask = urlSession.webSocketTask(with: url)
		setupBindings()
	}

	// MARK: - WSConnectionProtocol

	func start() {
		self.state = .started
		webSocketTask.resume()
	}

	func stop() {
		self.state = .idle
		webSocketTask.cancel(with: .normalClosure, reason: nil)
	}

	func sendMessage(message: String) {
		self.state = .active
		webSocketTask.send(.string(message), completionHandler: { _ in
		})
	}

	func sendMessage(message: Data) {
		self.state = .active
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
					if let data = responseMessage.data(using: .utf8) {
						do {
							let decodedData: ResponsePayload = try JSONDecoder().decode(ResponsePayload.self, from: data)
							self?.messageSubject.send(decodedData)
						} catch {
							self?.messageSubject.send(completion: .failure(error))
						}
					} else {
						self?.messageSubject.send(completion: .failure(WSConnectionError.malformedResponseData))
					}
				@unknown default: break
				}
				self?.setupBindings()
			case .failure(let failure):
				self?.stop()
				self?.messageSubject.send(completion: .failure(failure))
			}
		}
	}
}

extension WSConnection {
	/// Errors thrown by the `WSConnection`.
	enum WSConnectionError: LocalizedError {
		case invalidURL
		case malformedResponseData
		
		var errorDescription: String? {
			switch self {
			case .invalidURL:
				return "Could not create the target url from the given config's path"
			case .malformedResponseData:
				return "Data could not be deserialized"
			}
		}
	}
}
