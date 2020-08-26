//
//  BluetoothManager.swift
//

import Foundation
import CoreBluetooth

// MARK: Protocol
@objc public protocol BluetoothManagerProtocol: class {
    @objc optional func addedNewCharacteristic(characteristic: CBCharacteristic)
    @objc optional func didConnect(to: CBPeripheral)
    @objc optional func didUpdatePeripherals(peripherals: [CBPeripheral:[String:Any]])
}

// MARK: Structs
public struct Peripheral {
    var cbPeripheral: CBPeripheral
    var rssi: NSNumber
}

public struct CharacteristicData {
    var key: String
    var value: String
}

public class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: Variables
    // Singleton
    static let sharedInstance = BluetoothManager()
    
    // Protocol
    public var delegate: BluetoothManagerProtocol?
    
    // Core Bluetooth central manager
    var centralManager: CBCentralManager?
    
    // Dict to keep track of peripheral datas
    var discoveredPeripherals: [CBPeripheral:[String:Any]] = [CBPeripheral:[String:Any]]()
    
    // Array of Peripheral struct to show relevant data on cell
    var peripherals = [Peripheral]()
    
    // MARK: init
    override public init() {
        super.init()
        
        // Init the central with self as delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: CBCentralManager delegates
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Switch on the state for multiple state handling
        switch central.state {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            break
        case .poweredOff:
            break
        case .poweredOn:
            // Start scanning
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            break
        @unknown default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // First time seeing peripheral
        if discoveredPeripherals[peripheral] == nil {
            // Set self as delegate to invoke CBPeripheral functions
            peripheral.delegate = self
            
            // Create struct
            let periph = Peripheral(cbPeripheral: peripheral, rssi: RSSI)
            
            // Add struct to [Peripheral]
            peripherals.append(periph)
        }
        
        // Store (key, value) pair
        discoveredPeripherals[peripheral] = advertisementData
        
        // Add RSSI to dict
        discoveredPeripherals[peripheral]?["RSSI"] = RSSI
        
        // Notify delegate the peripherals were updated
        delegate?.didUpdatePeripherals?(peripherals: discoveredPeripherals)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Log event
        print("connected to \(peripheral)")
        
        // Discover the services for the perioheral that was just connected
        peripheral.discoverServices(nil)
        
        // Notify delegate for segue
        delegate?.didConnect?(to: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Log event
        print("disconnected from \(peripheral)")
    }
    
    // MARK: CBPeripheral delegates
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Guard services exist
        guard let services = peripheral.services else { return }
        
        // Loop through services and discover characteristics for each
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        // Guard characteristics exist
        guard let characteristics = service.characteristics else { return }
        
        // Loop through characteristics and read value for each
        for characteristic in characteristics {
            peripheral.readValue(for: characteristic)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // Notify delegate that a new characteristic was added
        delegate?.addedNewCharacteristic?(characteristic: characteristic)
    }
}
