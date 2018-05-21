//
//  BlueTools.swift
//  
//
//  Created by 黎峰麟 on 2017/4/10.
//  Copyright © 2017年 黎峰麟. All rights reserved.
//

import UIKit
import CoreBluetooth


//MARK:-  自定义连接状态枚举

public enum PeripheralEventStatus : Int {
    
    case disconnected                 //断开连接
    case connected                    //连接成功
    case failureconnected             //连接失败
    case update                       //扫描出新的设备
}


//MARK:-  定义闭包
//1 状态回调
typealias StatusCallBack = (_ peripheral : CBPeripheral ,_ status : PeripheralEventStatus)->Void
//2 蓝牙交互的值回调
typealias ValueCallBack = (_ peripheral : PeripheralModel ,_ chara : CBCharacteristic ,_ value : NSData)->Void



class BlueTools : NSObject{
    
    
    //MARK:-  单例对象
    static var shareIntance : BlueTools = BlueTools()
    
    //MARK:-  服务和特性UUID
    var serveceUUIDs : [CBUUID] = []
    //MARK:-  需要检索的特性
    var charaUUIDs : [String] = []
    
    //MARK:-  可见的所有设备
    var pers : [String : PeripheralModel] = [:]
    
    //MARK:-  外界连接的设备做保存
    var externalConnection : [CBPeripheral] = []
    
    
    //MARK:-  根据唯一标识符保存特性
    var characteristics : [String : [String : CBCharacteristic]] = [:]
    //MARK:-  蓝牙中心
    var manager : CBCentralManager = CBCentralManager()
    
    //蓝牙是否可用
    var isOn = false
    //内部读取连接的rssi值的定时器
    var rssiTimer : Timer?
    
    
    
    //MARK:-  DFU固件升级选择的设备
    var selectedPeripheral : CBPeripheral?
    
    
    
    
    
    
    //事件回调或值的回调
    var eventCallBack : StatusCallBack = {_,_ in}
    var valueCallBack : ValueCallBack = {_,_,_ in}

    
    //当对象被回收的时候取消所有连接的外设
    deinit {
        cancelConnectionAllDevice()
    }
    
}




//MARK:- CBPeripheralDelegate代理
extension BlueTools : CBPeripheralDelegate{
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        
        guard let characteris = service.characteristics else {
            return
        }
        
        
        var charas = characteristics[peripheral.identifier.uuidString]
        if charas == nil{charas = [:]}
        
        
        LFLLog(message: "服务 \(service.uuid.uuidString)")
        
        for chara in characteris {
            
            let charaUUID = chara.uuid.uuidString
            
            LFLLog(message: "特性 \(charaUUID)  \(chara.properties)")
            
            charas?[charaUUID] = chara
            peripheral.readValue(for: chara)
            peripheral.setNotifyValue(true, for: chara)
        }
        
        characteristics[peripheral.identifier.uuidString] = charas
        
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
        
        let uuid = peripheral.identifier.uuidString
        
        var model = pers[uuid]
        
        if model == nil{model = PeripheralModel(peripheral: peripheral, identifier: uuid,name :peripheral.name)}
        model?.rssi = RSSI.intValue
        pers[uuid] = model
        
        //回调外部bock
        eventCallBack(peripheral, .update)
    }
    
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let value = characteristic.value else {
            return
        }
        
        
        guard let peripher = pers[peripheral.identifier.uuidString] else {
            return
        }
        
        let dataInfo = value as NSData
        
        
        valueCallBack(peripher, characteristic, dataInfo)
        
//        let bytes = Array<UInt8>.dataToArr(data: dataInfo) as NSArray
        
        LFLLog(message: "更新新值 \(dataInfo) 特性UUID \(characteristic.uuid.uuidString)")
    }
    

}

//MARK:- CBCentralManager代理
extension BlueTools : CBCentralManagerDelegate{
    
    
    ///蓝牙状态更新
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn{
            isOn = true
            BlueTools.shareIntance.reconnectConnectedPerpheral()
        }else{
            isOn = false
            LFLLog(message: "蓝牙状态不可用")
        }
        
    }
    
    
    ///扫描出新的设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        let uuid = peripheral.identifier.uuidString
        let name = peripheral.name
        
        if (name != nil){
            
            var rssi = RSSI.intValue
            
//            if rssi < -60 {return}
            
            //进行排序
            if rssi == 127{rssi = -127}
            
            //取出之前保存的值
            var model = pers[uuid]
            if model == nil{model = PeripheralModel(peripheral: peripheral, identifier: uuid, name: name)}
            
            
            var macAddress : String?
            
            
            let data = advertisementData["kCBAdvDataManufacturerData"]
            
            //可选绑定
            if let data = data{
                
                let dataInfo = data as! NSData
                let bytes = Array<UInt8>.dataToArr(data: dataInfo) as NSArray
                let mac = bytes.subarray(with: NSRange(location: bytes.count - 6, length: 6)) as! Array<UInt8>
                
                macAddress = String(format: "%02X:%02X:%02X:%02X:%02X:%02X", arguments: mac)
            }
            
//            guard let data = advertisementData["kCBAdvDataManufacturerData"] else{
//                return
//            }
            
            
            
            
            model?.rssi = rssi
            model?.macAddress = macAddress
            
            //更新保存的外设
            pers[uuid] = model
            
            //回调外部bock扫描出了新的设备
            eventCallBack(peripheral, .update)
      
//            LFLLog(message: "name:\(String(describing: model?.name)) rrsi:\(String(describing: model?.rssi)) mac:\(String(describing: model?.macAddress))")
        }
        
    }
    
    
    ///链接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        updatePers(peripheral: peripheral,status: .connected)
        
        peripheral.delegate = self;
        peripheral.discoverServices(nil)
        
        //保存上一个已经链接的
        externalConnection.append(peripheral)
        
        //开启读取rssi值
        if rssiTimer == nil{
            rssiTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(BlueTools.readRRSI(timer:)), userInfo: nil, repeats: true)
        }
        
    }
    
    
    ///断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        //移除这个设备
        externalConnectionRemove(peripheral: peripheral)
        
        updatePers(peripheral: peripheral,status: .disconnected)
    }
    
    
    ///连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        //移除这个设备
        externalConnectionRemove(peripheral: peripheral)
        
        updatePers(peripheral: peripheral,status: .failureconnected)
    }
    
    
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        manager = central
        manager.delegate = self
        reconnectConnectedPerpheral()
    }
    
    
    
    

    
}

//MARK:-  私有方法(内部使用)  
extension BlueTools{
    
    
    //私有方法移除一个对象
    func externalConnectionRemove(peripheral : CBPeripheral){
        
//        for i in 0..<externalConnection.count {
//            
//            let per = externalConnection[i]
//            
//            if per.identifier.uuidString == peripheral.identifier.uuidString{
//                externalConnection.remove(at: i)
//                break
//            }
//        }
        
        guard let index = externalConnection.index(of: peripheral) else {return}
        externalConnection.remove(at: index)
    }

    
    //更新状态回调
    func updatePers(peripheral : CBPeripheral,status : PeripheralEventStatus) {
        
        let uuid = peripheral.identifier.uuidString
        guard let model = pers[uuid] else {
            return
        }
        model.peripheral = peripheral
        pers[uuid] = model
        
        //回调外部bock
        eventCallBack(peripheral, status)
    }
    
    
    //定时器读取信号值
    func readRRSI(timer : Timer) {
        
        let peripherals = self.manager.retrieveConnectedPeripherals(withServices: self.serveceUUIDs)
        
        for peripheral in peripherals {
            
            if (peripheral.state == .connected){
                peripheral.readRSSI()
            }
        }
    }
    
    
    
    
    //重连设备
    func reconnectConnectedPerpheral() {
        
        //1 retrievePeripheralsWithIdentifiers  如果设备已经保存了成员变量没被销毁就能去连接他
        //2 retrieveConnectedPeripheralsWithServices
        //3 如果以上两部都不行那从新开启扫描
        
//        let uuid = UUID(uuidString: "3E7A55E3-1AFD-4166-8F3B-037B7264609D")
        let uuid : UUID? = nil
        
        if (uuid != nil) && (pers.count != 0){
            
            let retrievePeripherals = manager.retrievePeripherals(withIdentifiers: [uuid!])
            
            if retrievePeripherals.count != 0 {
                
                for peripheral in retrievePeripherals {
                    
                    if (peripheral.state != .connected){
                       let options = [CBConnectPeripheralOptionNotifyOnConnectionKey:true,
                            CBConnectPeripheralOptionNotifyOnDisconnectionKey:true,
                            CBConnectPeripheralOptionNotifyOnNotificationKey:true]
                        manager.connect(peripheral, options: options)
                    }
                }
            }
            
        }else{
        
            let pers = connectedPeripherals()
            if pers.count == 0{
                starScan()
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}

//MARK:-  工具为外部提供的方法
extension BlueTools{
    
    //导入自己的蓝牙固件升级包进行升级
    func performDFU() -> Void {
        
    }
    
    
    //需要在外部设置下  在初始化的时候无法设置代理成功 不知为毛
    func configPlatforms(serveceUUIDs : [CBUUID] , charaUUIDs : [String]){
        self.serveceUUIDs = serveceUUIDs
        self.charaUUIDs = charaUUIDs
//        manager = CBCentralManager(delegate: BlueTools.shareIntance, queue: .main)
        
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true,
                       CBCentralManagerOptionRestoreIdentifierKey:"XXXIdentifierKey"] as [String : Any]
        manager = CBCentralManager(delegate: BlueTools.shareIntance, queue: .main, options: options)
    }
    

    //开启扫描
    func starScan() {
        manager.scanForPeripherals(withServices: serveceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    //关闭扫描
    func stopScan() {
        manager.stopScan()
    }
    
    
    //连接一个外设
    func connectingADevice(uuid : String){
        
        guard let model = pers[uuid] else {
            return
        }
        
        let peripheral = model.peripheral!
        
        if (peripheral.state != .connected){
            let options = [CBConnectPeripheralOptionNotifyOnConnectionKey:true,
                           CBConnectPeripheralOptionNotifyOnDisconnectionKey:true,
                           CBConnectPeripheralOptionNotifyOnNotificationKey:true]
            manager.connect(peripheral, options: options)
        }
        
    }
    
    
    //断开一个外设
    func cancelConnectionDevice(uuid : String) {
        
        guard let model = pers[uuid] else {
            return
        }
        
        let peripheral = model.peripheral!
        
        if peripheral.state == .connected {
            manager.cancelPeripheralConnection(peripheral)
            peripheral.delegate = nil
        }
    }
    
    
    
    //断开所有设备
    func cancelConnectionAllDevice() {
        
        let peripherals = manager.retrieveConnectedPeripherals(withServices: serveceUUIDs)
        
        for peripheral in peripherals {
            
            if peripheral.state == .connected {
                manager.cancelPeripheralConnection(peripheral)
                peripheral.delegate = nil
            }
        }

    }
    
    
    
    //写数据到一个某个设备的某个特性
    func write(identifier : String?,uuid : String,data : NSData){
        
        var identifier = identifier
        
        
        if  identifier == nil {
            
            guard let currentPeripheral = externalConnection.last?.identifier.uuidString else {
                return
            }
            
            identifier = currentPeripheral
        }
        
        
        guard let model = pers[identifier!] else {
            return
        }
        
        guard let onePerCharcas = characteristics[identifier!] else {
            return
        }
        
        guard let charca = onePerCharcas[uuid] else {
            return
        }
        
        model.peripheral?.writeValue(data as Data, for: charca, type: .withResponse)
    }
    
    
    
    
    // 检索当前已经链接的外设
    func connectedPeripherals () ->[String : PeripheralModel]{

        var pers : [String : PeripheralModel] = [:]

        let peripherals = manager.retrieveConnectedPeripherals(withServices: serveceUUIDs)

        for peripheral in peripherals {
            
            let uuid = peripheral.identifier.uuidString
            var model = pers[uuid]
            
            if model == nil{
                model = PeripheralModel(peripheral: peripheral, identifier: uuid,name :peripheral.name)
                pers[uuid] = model
            }
            
            if (peripheral.state != .connected){
                let options = [CBConnectPeripheralOptionNotifyOnConnectionKey:true,
                               CBConnectPeripheralOptionNotifyOnDisconnectionKey:true,
                               CBConnectPeripheralOptionNotifyOnNotificationKey:true]
                manager.connect(peripheral, options: options)
            }

        }
        
        return pers
    }
    
    
    
    
    ///通过信号值排序
    func sortedRssiPeripherals() -> [PeripheralModel] {
        
        var peripherals = Array(BlueTools.shareIntance.pers.values)
        
        if peripherals.count != 0{
            peripherals = peripherals.sorted(by: { (value0 : PeripheralModel, value1 : PeripheralModel) -> Bool in
                return value0.sortByRssi(model: value1)
            })
        }
        return peripherals
    }
    
    
    //通过唯一标识符排序字典
    func sortedIdentifierPeripherals() -> [PeripheralModel] {
        
        var peripherals = Array(BlueTools.shareIntance.pers.values)
        
        if peripherals.count != 0{
            peripherals = peripherals.sorted(by: { (value0 : PeripheralModel, value1 : PeripheralModel) -> Bool in
                return value0.sortByIdentifier(model: value1)
            })
        }
        return peripherals
    }
    
    
//    对字典进行排序的结果是一个 --> (元组类型的数组)
//    let sorted = pers.sorted { (value0, value1) -> Bool in
//
//        let resut = value0.value.identifier?.compare(value1.value.identifier!)
//
//        if resut == .orderedDescending{
//            return true
//        }else{
//            return false
//        }
//    }
    
    
    //重新扫描前清除设备
    func rescanThePurgeDevice() {
        
        for per in pers {
            if per.value.peripheral?.state != .connected{
                pers.removeValue(forKey: per.key)
            }
        }
    }
    
}


//MARK:-  检测蓝牙是否开启
extension BlueTools{

    func examinationBluetooth() {
        
        if !isOn{
            
            let alert = UIAlertController(title: "打开蓝牙来允许\"\(AppInfo.shareIntance.appName!)\"连接到配件", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .default, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    
}








