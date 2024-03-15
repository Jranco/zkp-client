//
//  Queue.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 06.03.24.
//

import Foundation

public struct Queue<Element> {
	public var count: Int { list.count }
	public private(set) var list = [Element]()
	
	public init(elements: [Element]) {
		self.list = elements
	}
	
	public mutating func enqueue(_ element: Element) {
		list.append(element)
	}
	@discardableResult
	public mutating func dequeue() -> Element? {
		if !list.isEmpty {
			return list.removeFirst()
		} else {
			return nil
		}
	}
	public mutating func dequeueAll() {
		list.removeAll()
	}
}
