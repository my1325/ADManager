//
//  Optional+Extensions.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

extension Optional where Wrapped == Bool {
    var boolValue: Bool {
        switch self {
        case .none:
            return false
        case let .some(value):
            return value
        }
    }
}

extension Optional where Wrapped == Int {
    var intValue: Int {
        switch self {
        case .none:
            return -1
        case let .some(value):
            return value
        }
    }
    
    static func > (lhs: Self, rhs: Int) -> Bool {
        switch lhs {
        case .none:
            return false
        case let .some(value):
            return value > rhs
        }
    }
}
