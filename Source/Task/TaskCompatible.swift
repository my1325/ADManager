//
//  TaskCompatible.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

public protocol TaskReumeResultDelegate: class {
    func task(_ task: TaskCompatible, didCompleteWithData data: Any?)
    
    func task(_ task: TaskCompatible, didCompleteWithError error: Error)
    
    func task(_ task: TaskCompatible, adDidLoad data: Any?)
}

public protocol TaskCompatible {
    var identifier: String { get }
    
    var isCanceled: Bool { get }
    
    var ad: ADCompatble { get }
    
    func cancel()
    
    func resume(_ delegate: TaskReumeResultDelegate)
    
    func retry() -> Bool
}
