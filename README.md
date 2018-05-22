# CoreBlue简易使用方法



/***初始化***/

    //这里需要填入自己需要使用的服务  ***** 1.为了指定服务扫描外设。2为了指定服务检索已连接的外设。                
    let serveces = [CBUUID(string: "填入自己服务")]
    BlueTools.shareIntance.configPlatforms(serveceUUIDs: serveces)

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
    
3 读取电量写入数据 (BlueWrite专一做写入操作可以根据自己的需求逐一添加方法去使用)
    
    guard let identifier = BlueTools.shareIntance.connectedPeripherals().keys.first else{return}
    BlueWrite.shareIntance.deviceInformation(type: 0x1804, identifier: identifier)
    
4 取消所有连接
    
    BlueTools.shareIntance.cancelConnectionAllDevice()
    
5  固件升级  ,这里需要自行完善 市面上的蓝牙芯片有好几种 升级的方式也有所不同   自行实现 performDFU()方法

    guard let peripheral = BlueTools.shareIntance.connectedPeripherals().values.first else{return}
    BlueTools.shareIntance.selectedPeripheral = peripheral.peripheral
    BlueTools.shareIntance.performDFU()
    
    
/***写数据到外设使用 -BlueWrite***/
    自行在BlueWrite中添加写入方法 如：
    
    func deviceInformation(type : Int , identifier : String){
        let bytes : [UInt8] = [0x04,UInt8(type)]
        let data = NSData(bytes: bytes, length: 2)
        BlueTools.shareIntance.write(identifier: identifier, uuid: "使用的某个特性", data: data)
    }
    





