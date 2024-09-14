//
//  WSConnectionState.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

/// WebSocket connection state with regard to its lifecycle.
enum WSConnectionState {
	case idle
	case started
	case active
}
