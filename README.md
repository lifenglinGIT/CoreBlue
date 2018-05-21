# CoreBlue简易使用方法


/***初始化***/

    //这里需要填入自己服务
    let serveces = [CBUUID(string: "填入自己服务")]
    //这里需要填入服务之下的特征值
    let charaUUIDs = ["特征值1","特征值2"]
    BlueTools.shareIntance.configPlatforms(serveceUUIDs: serveces, charaUUIDs: charaUUIDs)

    BlueTools.shareIntance.eventCallBack = {[weak self] (peripheral : CBPeripheral ,status : PeripheralEventStatus) ->() in
        //对设备信号值进行排序
        self?.tableViewData = BlueTools.shareIntance.sortedIdentifierPeripherals()
    }


//更新值

    BlueTools.shareIntance.valueCallBack = {(peripheralModel : PeripheralModel ,chara : CBCharacteristic ,value : NSData) ->() in
        LFLLog(message: peripheralModel.macAddress)
        LFLLog(message: "更新新值\(value) -- UUID \(chara.uuid.uuidString)")
    }



/***交互相关***/

1 开启扫描

    BlueTools.shareIntance.examinationBluetooth()
    //重新扫描前清除已经发现的设备
    BlueTools.shareIntance.rescanThePurgeDevice()
    BlueTools.shareIntance.starScan()

2 关闭扫描

    BlueTools.shareIntance.stopScan()
    
3 读取电量写入数据
    
    guard let identifier = BlueTools.shareIntance.connectedPeripherals().keys.first else{return}
    BlueWrite.shareIntance.deviceInformation(type: 0x1804, identifier: identifier)
    
4 取消所有连接
    
    BlueTools.shareIntance.cancelConnectionAllDevice()
    
5  固件升级  ,这里需要自行完善 市面上的蓝牙芯片有好几种 升级的方式也有所不同   自行实现 performDFU()方法

    guard let peripheral = BlueTools.shareIntance.connectedPeripherals().values.first else{return}
    BlueTools.shareIntance.selectedPeripheral = peripheral.peripheral
    BlueTools.shareIntance.performDFU()
    





