//
//  Atomic.swift
//  Panoramic
//
//  Created by Jun Tanaka on 2017/01/18.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import Foundation

internal final class Atomic<Value> {
	private let semaphore = DispatchSemaphore(value: 0)

	private var _value: Value

	var value: Value {
		get {
			semaphore.wait()
			defer { semaphore.signal() }

			return _value
		}
		set(newValue) {
			swap(with: newValue)
		}
	}

	init(_ value: Value) {
		_value = value
	}

	@discardableResult func swap(with newValue: Value) -> Value {
		semaphore.wait()
		defer { semaphore.signal() }

		let oldValue = _value
		_value = newValue
		return oldValue
	}

	@discardableResult func update(_ action: (Value) -> Value) -> Value {
		semaphore.wait()
		defer { semaphore.signal() }

		let newValue = action(_value)
		_value = newValue
		return newValue
	}
}
