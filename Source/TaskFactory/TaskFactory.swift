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

public final class ADRequest {
    let task: TaskCompatible
    let complete: ((Result<Any?, Error>) -> Void)?
    let adDidLoad: ((Any?) -> Void)?
    
    init(task: TaskCompatible, adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, Error>) -> Void)?) {
        self.task = task
        self.adDidLoad = adDidLoad
        self.complete = complete
    }
}

public final class ADResult {
    public let complete: ((Result<Any?, Error>) -> Void)?
    public let adDidLoad: ((Any?) -> Void)?
    public let task: TaskCompatible
    private var result: Any?
    
    public init(task: TaskCompatible, complete: ((Result<Any?, Error>) -> Void)?, adDidLoad: ((Any?) -> Void)?) {
        self.task = task
        self.complete = complete
        self.adDidLoad = adDidLoad
    }
    
    public func uploadResult(_ result: Any?) {
        self.result = result
    }
    
    public func immediatelyResult() {
        guard !task.isCanceled else { return }
        adDidLoad?(result)
    }
    
    public func completeWithResult(_ completeData: Result<Any?, Error>) {
        guard !task.isCanceled else { return }
        complete?(completeData)
    }
}

open class TaskFactory: TaskFactoryCompatible, TaskReumeResultDelegate {
    
    /// 最大的并发数量，默认为1
    public let maxConcurrentTaskCount: Int
    
    public private(set) var cacheQueue: [ADRequest] = []
    
    public private(set) var taskingQueue: [TaskCompatible] = []
    
    public private(set) var preloadedQueue: [ADCategory: [ADResult]] = [:]
    public private(set) var immediatelyQueue: [ADCategory: [ADResult]] = [:]
    
    open var taskingSize: Int {
        return _lock.synchronize { self.taskingQueue.count }
    }
    
    public let _lock = DispatchSemaphore(value: 1)

    public init(maxConcurrentTaskCount: Int = 1) {
        self.maxConcurrentTaskCount = maxConcurrentTaskCount
    }
    
    public func requestAd(_ ad: ADCompatble, _ adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, Error>) -> Void)?) -> TaskCompatible {
        switch ad.method {
        case .immediately:
            return immediatelyAD(ad, adDidLoad, complete: complete)
        case .preload:
            return preloadAd(ad, adDidLoad, complete: complete)
        }
    }
    
    private func immediatelyAD(_ ad: ADCompatble, _ adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, Error>) -> Void)?) -> TaskCompatible {
        let _loadedResult = preloadedQueue[ad.category] ?? []
        if _loadedResult.count > 0 {
            
            let adResult = _loadedResult[0]
            adResult.immediatelyResult()
            return adResult.task
        } else if taskingSize < maxConcurrentTaskCount {
            
            let task = prepareFor(ad)
            var _immediatelyResult = immediatelyQueue[ad.category] ?? []
            _immediatelyResult.append(ADResult(task: task, complete: complete, adDidLoad: adDidLoad))
            immediatelyQueue[ad.category] = _immediatelyResult
            immediatelyResumeTask(task)
            return task
        } else {
            
            let task = prepareFor(ad)
            cacheQueue.append(ADRequest(task: task, adDidLoad: adDidLoad, complete: complete))
            return task
        }
    }
    
    private func preloadAd(_ ad: ADCompatble, _ adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, Error>) -> Void)?) -> TaskCompatible {
        
        if taskingSize < maxConcurrentTaskCount {
            let task = prepareFor(ad)
            var _preloadResult = preloadedQueue[ad.category] ?? []
            _preloadResult.append(ADResult(task: task, complete: complete, adDidLoad: adDidLoad))
            preloadedQueue[ad.category] = _preloadResult
            immediatelyResumeTask(task)
            return task
            
        } else {
            let task = prepareFor(ad)
            cacheQueue.append(ADRequest(task: task, adDidLoad: adDidLoad, complete: complete))
            return task
        }
    }
    
    private func immediatelyResumeTask(_ task: TaskCompatible) {
        _lock.synchronize { [unowned self] in
            self.taskingQueue.append(task)
            task.resume(self)
        }
    }

    open func prepareFor(_ ad: ADCompatble) -> TaskCompatible {
        abstractMethod()
    }
    
    private func castValueOrFatalError<V>(_ value: Any, _ message: String) -> V {
        guard let _retValue = value as? V else {
            fatalError(message)
        }
        return _retValue
    }
    
    private func dequeuPoolTask() -> ADRequest? {
        return _lock.synchronize {
            if self.cacheQueue.count > 0 {
                return self.cacheQueue.removeFirst()
            } else {
                return nil
            }
        }
    }

    open func task(_ task: TaskCompatible, adDidLoad data: Any?) {
        switch task.ad.method {
        case .preload:
            let _preloadResult = preloadedQueue[task.ad.category]
            if let _result = _preloadResult, _result.count > 0 {
                let result = _preloadResult?[0]
                result?.uploadResult(data)
            }
        case .immediately:
            let _immediatelyResult = immediatelyQueue[task.ad.category]
            if let _result = _immediatelyResult, _result.count > 0 {
                let result = _immediatelyResult?[0]
                result?.uploadResult(data)
                result?.immediatelyResult()
            }
        }
    }
    
    open func task(_ task: TaskCompatible, didCompleteWithData data: Any?) {
        taskingQueue.removeAll(where: { $0.identifier == task.identifier })
        if let _request = dequeuPoolTask() {
            _ = requestAd(_request.task.ad, _request.adDidLoad, complete: _request.complete)
        }
        switch task.ad.method {
        case .preload:
            
            var _preloadResult = preloadedQueue[task.ad.category]
            if let _result = _preloadResult, _result.count > 0 {
                let result = _preloadResult?.removeFirst()
                result?.completeWithResult(.success(data))
                preloadedQueue[task.ad.category] = _preloadResult
            }
        case .immediately:
            
            var _immediatelyResult = immediatelyQueue[task.ad.category]
            if let _result = _immediatelyResult, _result.count > 0 {
                let result = _immediatelyResult?.removeFirst()
                result?.completeWithResult(.success(data))
                immediatelyQueue[task.ad.category] = _immediatelyResult
            }
        }
    }
    
    open func task(_ task: TaskCompatible, didCompleteWithError error: Error) {
        retryTaskIfCould(task, error: error)
    }
    
    private func retryTaskIfCould(_ task: TaskCompatible, error: Error) {
        if !task.retry() {
            switch task.ad.method {
            case .preload:
                
                var _preloadResult = preloadedQueue[task.ad.category]
                if let _result = _preloadResult, _result.count > 0 {
                    let result = _preloadResult?.removeFirst()
                    result?.completeWithResult(.failure(error))
                    preloadedQueue[task.ad.category] = _preloadResult
                }
            case .immediately:
                
                var _immediatelyResult = immediatelyQueue[task.ad.category]
                if let _result = _immediatelyResult, _result.count > 0 {
                    let result = _immediatelyResult?.removeFirst()
                    result?.completeWithResult(.failure(error))
                    immediatelyQueue[task.ad.category] = _immediatelyResult
                }
            }
            
            taskingQueue.removeAll(where: { $0.identifier == task.identifier })
            if let _request = dequeuPoolTask() {
                _ = requestAd(_request.task.ad, _request.adDidLoad, complete: _request.complete)
            }
        }
    }
}
