//
//  Lock.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

@inline(__always)
public func synchronizedOn<T>(_ target: Any, _ code: () throws -> T) rethrows -> T {
    objc_sync_enter(target); defer { objc_sync_exit(target) }
    return try code()
}

public protocol LockCompatible {
    func lock()
    
    func unlock()
}

extension LockCompatible {
    public func synchronize<T>(_ code: @escaping () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try code()
    }
}

extension NSLock: LockCompatible {}

extension DispatchSemaphore: LockCompatible {
    public func lock() {
        wait()
    }
    
    public func unlock() {
        signal()
    }
}

