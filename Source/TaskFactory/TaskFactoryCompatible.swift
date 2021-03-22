//
//  ADTaskFactory.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

public protocol TaskFactoryCompatible {
    func requestAd(_ ad: ADCompatble, _ adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, NSError>) -> Void)?) -> TaskCompatible
}

public final class NoneTask: TaskCompatible {

    public var identifier: String = "None"
    
    public var isCanceled: Bool = true
    
    public var ad: ADCompatble = NoneAd()
    
    public func cancel() {}
    
    public func resume(_ delegate: TaskReumeResultDelegate) {}
    
    public func retry() -> Bool {
        return false 
    }
    
    public init() {}
}

struct NoneTaskFactory: TaskFactoryCompatible {
    func requestAd(_ ad: ADCompatble, _ adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, NSError>) -> Void)?) -> TaskCompatible {
        return NoneTask()
    }
}

