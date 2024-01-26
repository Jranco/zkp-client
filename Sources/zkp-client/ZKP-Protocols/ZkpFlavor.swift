//
//  ZkpFlavor.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import Foundation

/// The various types of the supported zero-knowledge protocols.
/// The respective configurations may vary, thus the usage of the associated values.
public enum ZkpFlavor: Codable {
	case fiatShamir(config: FiatShamir.Config)

	var name: String {
		switch self {
		case .fiatShamir(_): return "fiatShamir"
		}
	}
}
