//
//  ZKPFlavorFactoryProtocol.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 26.01.24.
//

import Foundation

/// A protocol defining requirements for a factory creating an instance of a `zero-knowledge` protocol flavor.
protocol ZKPFlavorFactoryProtocol {
	/// The factory method creating an instance of a `zero-knowledge` protocol flavor.
	func createZKP() throws -> any ZeroKnowledgeProtocol
}
