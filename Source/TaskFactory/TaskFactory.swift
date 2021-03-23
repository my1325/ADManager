//
//  TaskFactory.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

func abstractMethod<T>(_ method: String = #function, _ line: Int = #line) -> T {
    fatalError("not implemente method \(method) at line \(line)")
}

func abstractMethodEmptyImplement(_ method: String = #function, _ line: Int = #line) {
    #if DEBUG
    print("abstract method \(method) at line \(line) not implement")
    #endif
}

open class TaskFactory: TaskFactoryCompatible {
    public typealias ADDidLoad = (Any?) -> Void
    public typealias ADComplete = (Result<Any?, NSError>) -> Void
    
    public struct ADRequest {
        let ad: ADCompatble
        let adDidLoad: ADDidLoad?
        let adComplete: ADComplete?
        let task: TaskCompatible
    }
    
    public init() {}
    
    public private(set) var cacheQueue: [ADCategory: [ADRequest]] = [:]
    
    public private(set) var taskingQueue: [ADCategory: ADRequest] = [:]
    
    public func requestAd(_ ad: ADCompatble, _ adDidLoad: ADDidLoad?, complete: ADComplete?) -> TaskCompatible {
        let task = prepareFor(ad)
        let request = ADRequest(ad: ad, adDidLoad: adDidLoad, adComplete: complete, task: task)
        let taskingTask = taskingQueue[ad.category]
        if taskingTask != nil, !taskingTask!.task.isCanceled {
            var _cacheQueue = cacheQueue[ad.category] ?? []
            _cacheQueue.append(request)
            cacheQueue[ad.category] = _cacheQueue
        } else if taskingTask?.task.isCanceled == true {
            cacheQueue.removeValue(forKey: ad.category)
            resumeRequest(request, with: task)
        } else {
            resumeRequest(request, with: task)
        }
        return task
    }
    
    open func prepareFor(_ ad: ADCompatble) -> TaskCompatible {
        abstractMethod()
    }
    
    public func dequeueRequestForAdCategory(_ category: ADCategory) -> ADRequest? {
        var _cacheQueue = cacheQueue[category] ?? []
        if !_cacheQueue.isEmpty {
            let _reqeust = _cacheQueue.removeFirst()
            cacheQueue[category] = _cacheQueue
            return _reqeust
        } else {
            for (_category, _cacheQueue) in cacheQueue {
                if !_cacheQueue.isEmpty {
                    var __cacheQueue = _cacheQueue
                    let _reqeust = __cacheQueue.removeFirst()
                    cacheQueue[_category] = __cacheQueue
                    return _reqeust
                }
            }
            return nil
        }
    }
    
    private func resumeRequest(_ request: ADRequest, with task: TaskCompatible) {
        taskingQueue[task.ad.category] = request
        task.resume(self)
    }
    
    private func requestNext(_ category: ADCategory) {
        if let _newRequest = dequeueRequestForAdCategory(category), !_newRequest.task.isCanceled {
            resumeRequest(_newRequest, with: _newRequest.task)
        }
    }
}

extension TaskFactory: TaskReumeResultDelegate {
    public func task(_ task: TaskCompatible, didCompleteWithData data: Any?) {
        let request = taskingQueue.removeValue(forKey: task.ad.category)
        if let _request = request, !task.isCanceled {
            _request.adComplete?(.success(data))
        }
        
        requestNext(task.ad.category)
    }
    
    public func task(_ task: TaskCompatible, didCompleteWithError error: Error) {
        if !task.isCanceled, task.retry() { return }
        
        let request = taskingQueue.removeValue(forKey: task.ad.category)
        if let _request = request, !task.isCanceled {
            _request.adComplete?(.failure(error as NSError))
        }
        
        requestNext(task.ad.category)
    }
    
    public func task(_ task: TaskCompatible, adDidLoad data: Any?) {
        if task.isCanceled { taskingQueue.removeValue(forKey: task.ad.category) }
        
        if let _request = taskingQueue[task.ad.category] {
            _request.adDidLoad?(data)
        } else {
            requestNext(task.ad.category)
        }
    }
}
