//
//  ViewController.swift
//  
//
//  Created by 黎峰麟 on 2017/4/7.
//  Copyright © 2017年 黎峰麟. All rights reserved.
//

import UIKit
import CoreBluetooth



class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var btn0: UIButton!
    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn3: UIButton!
    
    
    
    //MARK:-  表单的数据源
    var tableViewData : [PeripheralModel] = [PeripheralModel](){
    
        //属性监听器
        didSet{
            //刷新列表
            tableView .reloadData()
        }
    }
    
    
    let discoveriesTableViewCellIdentifier = "CellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        
        //配置蓝牙信息
        configPlatformsBlueTool()
        
        
        LFLLog(message: AppInfo.shareIntance.appName)
        LFLLog(message: AppInfo.shareIntance.version)
        LFLLog(message: UIDevice.current.isPad)
        LFLLog(message: UIDevice.current.isPhone)
        LFLLog(message: UIDevice.current.systemVersion)
    }
}


// MARK: UITableViewDelegate UITableViewDataSource

extension ViewController : UITableViewDelegate,UITableViewDataSource{

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: discoveriesTableViewCellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: discoveriesTableViewCellIdentifier)
        }
        
        let per = tableViewData[indexPath.row]
        
        
        let state = per.peripheral?.state
        
        
        var statue = ""
        
        if state == .connected{
            statue = "connected"
        }else if state == .connecting{
            statue = "connecting"
        }else if state == .disconnected{
            statue = "disconnected"
        }else if state == .disconnecting{
            statue = "disconnecting"
        }
        
        
        cell?.textLabel?.text = "\(per.name!) -- \(per.rssi) -- \(statue)  "
        cell?.detailTextLabel?.text = per.macAddress
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let per = tableViewData[indexPath.row]
        
        guard let state = per.peripheral?.state else {
            return
        }
        
        
        if state == .connected{
            BlueTools.shareIntance.cancelConnectionDevice(uuid: per.identifier!)
        }else if state == .disconnected{
            BlueTools.shareIntance.connectingADevice(uuid: per.identifier!)
        }
        
    }
}





//MARK:-  事件处理

extension ViewController{

    @IBAction func btnClick(_ sender: UIButton) {
        
        switch sender.tag {
        case 0:
            print("开启扫描")
            
            BlueTools.shareIntance.examinationBluetooth()
            
            //重新扫描前清除已经发现的设备
            BlueTools.shareIntance.rescanThePurgeDevice()
            BlueTools.shareIntance.starScan()
        case 1:
            print("停止扫描")
            BlueTools.shareIntance.stopScan()
        case 2:
            
            guard let identifier = BlueTools.shareIntance.connectedPeripherals().keys.first else{
                return
            }
            print("读取电量  \(identifier)")
            
            BlueWrite.shareIntance.deviceInformation(type: 0x1804, identifier: identifier)
        case 3:
            LFLLog(message: "获取已经链接的设备")
            LFLLog(message: " \(BlueTools.shareIntance.connectedPeripherals())")
        case 4:
            LFLLog(message: "取消所有连接")
            BlueTools.shareIntance.cancelConnectionAllDevice()
        case 5:
            LFLLog(message: "固件升级  ,这里需要自行完善 市面上的蓝牙芯片有好几种 升级的方式也有所不同  ")
            guard let peripheral = BlueTools.shareIntance.connectedPeripherals().values.first else{
                return
            }
            BlueTools.shareIntance.selectedPeripheral = peripheral.peripheral
            BlueTools.shareIntance.performDFU()

        default:
            break
        }
    }
}



//MARK:- 配置蓝牙信息和处理回调

extension ViewController{


    func configPlatformsBlueTool() {
        
        
        //这里需要填入自己服务
        let serveces = [CBUUID(string: "1892")]
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
    }
}













