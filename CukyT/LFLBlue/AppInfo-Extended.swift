//
//  UIDevice-Extended.swift
//  蓝牙封装
//
//  Created by 黎峰麟 on 2017/4/21.
//  Copyright © 2017年 黎峰麟. All rights reserved.
//

import UIKit

//MARK:-  APP信息的扩展          SWIFT字符串 和 OC是无缝转换
class AppInfo {
    
    var appName : String?
    var version : String?
    
    //单例对象
    static var shareIntance : AppInfo{
    
        let app = AppInfo()
        
        let info = Bundle.main.infoDictionary
        
        app.appName = info!["CFBundleDisplayName"] as? String
        app.version = info!["CFBundleShortVersionString"] as? String
        
        return app
    }
    
}


extension UIDevice{

    var isPad : Bool {
        get {return UI_USER_INTERFACE_IDIOM() == .pad}
    }
    
    var isPhone : Bool{
        get{return UI_USER_INTERFACE_IDIOM() == .phone}
    }
    
}
