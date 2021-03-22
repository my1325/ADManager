//
//  AD.swift
//  pangle_flutter
//
//  Created by my on 2021/3/11.
//

import Foundation

public typealias TaskFactoryCategory = String
public typealias ADCategory = String

public protocol ADCompatble {
    var taskFactoryCategory: TaskFactoryCategory { get }
        
    var category: ADCategory { get }
}

public struct NoneAd: ADCompatble {
    
    public static let noneTaskFactory: TaskFactoryCategory = "com.my.ad.manager.task.factory.none"
    
    public static let noneAdCategory: ADCategory = "com.my.ad.manager.ad.category.none"
        
    public var taskFactoryCategory: TaskFactoryCategory {
        return NoneAd.noneTaskFactory
    }
    
    public var category: ADCategory {
        return NoneAd.noneAdCategory
    }
}
