//
//  BlueWrite.swift
//  
//
//  Created by 黎峰麟 on 2017/4/12.
//  Copyright © 2017年 黎峰麟. All rights reserved.
//

import UIKit

class BlueWrite: NSObject {
    
    //MARK:-  保存了唯一标示符 使用单例去写
    static var shareIntance : BlueWrite = BlueWrite()
    
}



extension BlueWrite{

    //MARK:-  获取设备电量
    func deviceInformation(type : Int , identifier : String){
        
        let bytes : [UInt8] = [0x04,UInt8(type)]
        let data = NSData(bytes: bytes, length: 2)
        BlueTools.shareIntance.write(identifier: identifier, uuid: "2A92", data: data)
    }
    
}

