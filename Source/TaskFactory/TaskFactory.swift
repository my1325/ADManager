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
        adDidLoad?(result)
    }
    
    public func completeWithResult(_ completeData: Result<Any?, Error>) {
        complete?(completeData)
    }
}

open class TaskFactory: TaskFactoryCompatible, TaskReumeResultDelegate, TaskQueueDelegate {
    
    public let queue: TaskQueue
    
    /// 最大的并发数量，默认为1
    public let maxConcurrentTaskCount: Int
    /// task执行的线程队列
    public let dispatchQueue: DispatchQueue
    
    public private(set) var taskingQueue: [TaskCompatible] = []
    
    public private(set) var preloadedQueue: [ADCategory: [ADResult]] = [:]
    public private(set) var immediatelyQueue: [ADCategory: [ADResult]] = [:]
    
    open var taskingSize: Int {
        return _lock.synchronize { self.taskingQueue.count }
    }
    
    public let _lock = DispatchSemaphore(value: 1)

    public init(queue: TaskQueue,
                maxConcurrentTaskCount: Int = 1,
                dispatchQueue: DispatchQueue = DispatchQueue(label: "com.pangle.ad.manager.dispatch.queue", attributes: .concurrent))
    {
        self.queue = queue
        self.maxConcurrentTaskCount = maxConcurrentTaskCount
        self.dispatchQueue = dispatchQueue
    
        queue.delegate = self
    }
    
    public convenience init(maxTaskCapacity: Int = 10,
                            maxConcurrentTaskCount: Int = 1,
                            dispatchQueue: DispatchQueue = DispatchQueue(label: "com.pangle.ad.manager.dispatch.queue", attributes: .concurrent))
    {
        self.init(queue: TaskQueue(maxCapacity: maxTaskCapacity), maxConcurrentTaskCount: maxConcurrentTaskCount, dispatchQueue: dispatchQueue)
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
        var _loadedResult = preloadedQueue[ad.category] ?? []
        
        if _loadedResult.count > 0 {
            let adResult = _loadedResult.removeFirst()
            adResult.immediatelyResult()
            preloadedQueue[ad.category] = _loadedResult
            return adResult.task
            
        } else if taskingSize < maxConcurrentTaskCount {
            
            let task = prepareTaskWithArguments(ad)
            var _immediatelyResult = immediatelyQueue[ad.category] ?? []
            _immediatelyResult.append(ADResult(task: task, complete: complete, adDidLoad: adDidLoad))
            immediatelyQueue[ad.category] = _immediatelyResult
            immediatelyResumeTask(task)
            return task
        } else {
            
            let task = prepareTaskWithArguments(ad)
            queue.addTask(task)
            return task
        }
    }
    
    private func preloadAd(_ ad: ADCompatble, _ adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, Error>) -> Void)?) -> TaskCompatible {
        
        if taskingSize < maxConcurrentTaskCount {
            let task = prepareTaskWithArguments(ad)
            var _preloadResult = preloadedQueue[ad.category] ?? []
            _preloadResult.append(ADResult(task: task, complete: complete, adDidLoad: adDidLoad))
            preloadedQueue[ad.category] = _preloadResult
            immediatelyResumeTask(task)
            return task
            
        } else {
            let task = prepareTaskWithArguments(ad)
            queue.addTask(task)
            return task
        }
    }
    
    private func immediatelyResumeTask(_ task: TaskCompatible) {
        _lock.synchronize { [unowned self] in
            self.taskingQueue.append(task)
            task.resume(self)
        }
    }
    
    open func prepareTaskWithArguments(_ ad: ADCompatble) -> TaskCompatible {
        abstractMethod()
    }
    
    private func castValueOrFatalError<V>(_ value: Any, _ message: String) -> V {
        guard let _retValue = value as? V else {
            fatalError(message)
        }
        return _retValue
    }
    
    private func dequeuPoolTask() -> TaskCompatible {
        return _lock.synchronize { self.queue.dequeueTask() }
    }

    open func taskQueue(_ queue: TaskQueue, didEnterTask task: TaskCompatible) {
        abstractMethodEmptyImplement()
    }

    open func taskQueue(_ queue: TaskQueue, didFailEnterTask task: TaskCompatible) {
        taskAddPoolFailed(task)
    }
    
    open func taskAddPoolFailed(_ task: TaskCompatible) {
        abstractMethodEmptyImplement()
    }
    
    open func task(_ task: TaskCompatible, adDidLoad data: Any?) {
        switch task.ad.method {
        case .preload:
            var _preloadResult = preloadedQueue[task.ad.category]
            if _preloadResult?.count > 0 {
                let result = _preloadResult?.removeFirst()
                result?.uploadResult(data)
                preloadedQueue[task.ad.category] = _preloadResult
            }
        case .immediately:
            var _immediatelyResult = immediatelyQueue[task.ad.category]
            if _immediatelyResult?.count > 0 {
                let result = _immediatelyResult?.removeFirst()
                result?.uploadResult(data)
                result?.immediatelyResult()
                immediatelyQueue[task.ad.category] = _immediatelyResult
            }
        }
    }
    
    open func task(_ task: TaskCompatible, didCompleteWithData data: Any?) {
        immediatelyResumeTask(dequeuPoolTask())
        switch task.ad.method {
        case .preload:
            
            var _preloadResult = preloadedQueue[task.ad.category]
            if _preloadResult?.count > 0 {
                let result = _preloadResult?.removeFirst()
                result?.completeWithResult(.success(data))
                preloadedQueue[task.ad.category] = _preloadResult
            }
        case .immediately:
            
            var _immediatelyResult = immediatelyQueue[task.ad.category]
            if _immediatelyResult?.count > 0 {
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
                if _preloadResult?.count > 0 {
                    let result = _preloadResult?.removeFirst()
                    result?.completeWithResult(.failure(error))
                    preloadedQueue[task.ad.category] = _preloadResult
                }
            case .immediately:
                
                var _immediatelyResult = immediatelyQueue[task.ad.category]
                if _immediatelyResult?.count > 0 {
                    let result = _immediatelyResult?.removeFirst()
                    result?.completeWithResult(.failure(error))
                    immediatelyQueue[task.ad.category] = _immediatelyResult
                }
            }
            
            taskingQueue.removeAll(where: { $0.identifier == task.identifier })
            immediatelyResumeTask(dequeuPoolTask())
        }
    }
}
