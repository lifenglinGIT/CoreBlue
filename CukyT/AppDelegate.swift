//
//  AppDelegate.swift
//  
//
//  Created by 黎峰麟 on 2017/4/7.
//  Copyright © 2017年 黎峰麟. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}

//MARK:-  全局打印 在编译设置中 添加 swift flag -D DEBUG

func LFLLog<T>(message: T ,file: String = #file, funcName: String = #function, linNun: Int = #line) {
    
    #if DEBUG
        let fileName = (file as NSString).lastPathComponent
//        print("\(funcName)")
        print("\(fileName):\(linNun)-\(message)")
    #endif
    
}
