//
//  DBPer.swift
//  
//
//  Created by 黎峰麟 on 2017/4/10.
//  Copyright © 2017年 黎峰麟. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralModel: NSObject {

    
    //MARK:-  用户
    var uid : String?
    //MARK:-  唯一标识符
    var identifier : String?
    //MARK:-  mac地址
    var macAddress : String?
    //MARK:-  名称
    var name : String?
    //MARK:-  信号值
    var rssi : Int = 0
    //当前设备
    var peripheral : CBPeripheral?
    //是否需要重连
    var isNeedReconnection = true
    //昵称
    var nickName : String?
    
    
    
    
    //初始化方法
    init(peripheral : CBPeripheral,identifier : String, name : String?) {
        self.peripheral = peripheral
        self.identifier = identifier
        self.name = name
    }
    
    
    
    //通过RSSI排序
    func sortByRssi(model : PeripheralModel) -> Bool {
        
        if rssi > model.rssi{
            return true
        }else{
            return false
        }
    }
    
    //通过Identifier排序
    func sortByIdentifier(model : PeripheralModel) -> Bool {
        
        let resut = identifier?.compare(model.identifier!)
        
        if resut == .orderedAscending{
            return true
        }else{
            return false
        }
    }
    
}
