//
//  ADManager.swift
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

public final class ADManager {
    
    public static let shared = ADManager()
    
    private var factoryList: [TaskFactoryCategory: TaskFactoryCompatible] = [NoneAd.noneTaskFactory: NoneTaskFactory()]
    
    public func request(_ ad: ADCompatble, adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, NSError>) -> Void)?) -> TaskCompatible {
        if let _factory = taskFactoryForCategory(ad.taskFactoryCategory) {
            return _factory.requestAd(ad, adDidLoad, complete: complete)
        } else {
            fatalError("none register task factory for category \(ad.taskFactoryCategory)")
        }
    }
    
    public func taskFactoryForCategory(_ category: TaskFactoryCategory) -> TaskFactoryCompatible? {
        return factoryList[category]
    }
    
    public func register(_ category: TaskFactoryCategory, factory: TaskFactoryCompatible) {
        synchronizedOn(self) {
            self.factoryList[category] = factory
        }
    }
    
    public func unregister(_ category: TaskFactoryCategory) {
        synchronizedOn(self) {
            self.factoryList[category] = nil
        }
    }
}
