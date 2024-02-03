//
//  FiatShamirError.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 03.02.24.
//

import Foundation

/// Error cases thrown by the protocol.
enum FiatShamirError: LocalizedError {
	case unavailableDeviceID
	case couldNotConvertDeviceIDToInteger
	public var errorDescription: String? {
		switch self {
		case .unavailableDeviceID:
			return "The unique device identifier cannot be retrieved at the moment, please try again later. This happens, for example, after the device has been restarted but before the user has unlocked the device"
		case .couldNotConvertDeviceIDToInteger:
			return "Device identifier is not in a format that can be transformed into an integer number"
		}
	}
}
