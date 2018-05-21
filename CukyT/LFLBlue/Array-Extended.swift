//
//  NSData-Extended.swift
//  
//
//  Created by 黎峰麟 on 2017/4/11.
//  Copyright © 2017年 黎峰麟. All rights reserved.
//

import UIKit


//MARK:-  字节转成数组  为系统扩充方法

extension Array {
    
    static func dataToArr(data : NSData) -> Array<UInt8> {
        
        var bytes:[UInt8] = [UInt8]()
        
        
        for i in 0..<data.length {
            var temp:UInt8 = 0
            data.getBytes(&temp, range: NSRange(location: i,length:1 ))
            bytes.append(temp)
        }
        
        return bytes
    }
    
}
