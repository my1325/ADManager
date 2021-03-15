//
//  ADManager.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

public final class ADManager {
    
    public let `shared` = ADManager()
    
    private var factoryList: [TaskFactoryCategory: TaskFactoryCompatible] = [NoneAd.noneTaskFactory: NoneTaskFactory()]
    
    public func request(_ ad: ADCompatble, adDidLoad: ((Any?) -> Void)?, complete: ((Result<Any?, Error>) -> Void)?) -> TaskCompatible {
        return taskFactoryForCategory(ad.taskFactoryCategory).requestAd(ad, adDidLoad, complete: complete)
    }
    
    private func taskFactoryForCategory(_ category: TaskFactoryCategory) -> TaskFactoryCompatible {
        return synchronizedOn(self, {
            guard let _factory = self.factoryList[category] else {
                fatalError("none register task factory for category \(category)")
            }
            return _factory
        })
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
