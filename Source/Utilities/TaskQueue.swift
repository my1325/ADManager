//
//  TaskQueue.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

public protocol TaskQueueDelegate: class {
    func taskQueue(_ queue: TaskQueue, didEnterTask task: TaskCompatible)
    func taskQueue(_ queue: TaskQueue, didFailEnterTask task: TaskCompatible)
}

extension TaskQueueDelegate {
    public func taskQueue(_ queue: TaskQueue, didEnterTask task: TaskCompatible) {}
    
    public func taskQueue(_ queue: TaskQueue, didFailEnterTask task: TaskCompatible) {}
}

public final class TaskQueue {
    
    public weak var delegate: TaskQueueDelegate?
    
    /// queue的最大容量, 默认为10
    public let maxCapacity: Int
        
    private var taskPool: [TaskCompatible] = []
    
    /// 当信号量为1的时候当锁
    fileprivate let _lock: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    public init(maxCapacity: Int = 10) {
        self.maxCapacity = maxCapacity
    }

    public func addTask(_ task: TaskCompatible) {
        if taskPool.count < maxCapacity {
            addTaskToPool(task)
            delegate?.taskQueue(self, didEnterTask: task)
        } else {
            delegate?.taskQueue(self, didFailEnterTask: task)
        }
    }
    
    public func dequeueTask() -> TaskCompatible {
        return _lock.synchronize({ self.taskPool.removeFirst() })
    }
    
    private func addTaskToPool(_ task: TaskCompatible) {
        _lock.synchronize {
            self.taskPool.append(task)
        }
    }
}
