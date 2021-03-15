//
//  AD.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

public protocol ADType {}

public typealias TaskFactoryCategory = String
public typealias ADCategory = String

public enum LoadMethod {
    /// 预加载
    case preload
    /// 执行
    case immediately
}

public protocol ADCompatble: ADType {
    var taskFactoryCategory: TaskFactoryCategory { get }
    
    var method: LoadMethod { get }
    
    var category: ADCategory { get }
}

public struct NoneAd: ADCompatble {
    
    public static let noneTaskFactory: TaskFactoryCategory = "com.my.ad.manager.task.factory.none"
    
    public static let noneAdCategory: ADCategory = "com.my.ad.manager.ad.category.none"
    
    public var method: LoadMethod {
        return .preload
    }
    
    public var taskFactoryCategory: TaskFactoryCategory {
        return NoneAd.noneTaskFactory
    }
    
    public var category: ADCategory {
        return NoneAd.noneAdCategory
    }
}
