//
//  PeripheralTableViewController.swift
//

import UIKit
import CoreBluetooth

class PeripheralTableViewController: UITableViewController, BluetoothManagerProtocol {
     
    // MARK: Variables
    // Cell and segue identifiers
    var peripheralCellIdentifier = "PeripheralTableViewCell_identifier"
    var detailSegueIdentifier = "PeripheralDetailTableViewController_segue"
    var rowHeight: CGFloat = 70
    
    // Peripheral that was selected/tapped on in table view
    var selectedPeripheral: Peripheral? = nil
    
    // The characteristic data for the selected peripheral
    var selectedPeripheralCharacteristics: [CharacteristicData]? = nil
    
    // Populated from BluetoothManager
    var discoveredPeripherals = [CBPeripheral:[String:Any]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove excess empty cells
        tableView.tableFooterView = UIView()
        
        // Set title
        title = "BLE Scanner"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Listening on BluetoothManagerProtocol
        BluetoothManager.sharedInstance.delegate = self
    }

    // MARK: Table view delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Number of Peripheral structs that exist
        return BluetoothManager.sharedInstance.peripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: peripheralCellIdentifier, for: indexPath)
        
        // Get peripheral struct from manager
        let peripheral = BluetoothManager.sharedInstance.peripherals[indexPath.row]
        
        // Configure cell
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView?.isHidden = false
        cell.detailTextLabel?.text = ""
        
        // Set cell texts
        cell.textLabel?.text = peripheral.cbPeripheral.name ?? "Unnamed"
        cell.detailTextLabel?.text = peripheral.rssi.description
        
        // Give random system image
        if #available(iOS 13.0, *) {
            cell.imageView?.image = UIImage(systemName: "radiowaves.right")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Header label
        return "Available Devices: " + discoveredPeripherals.count.description
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Clear old selected variables
        selectedPeripheral = nil
        selectedPeripheralCharacteristics = nil
        
        // Deselecte the row
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the peripheral
        let peripheral = BluetoothManager.sharedInstance.peripherals[indexPath.row]
        
        // Set new selected peripheral
        selectedPeripheral = peripheral
        
        // Connect to the peripheral with notify connect/disconnect
        BluetoothManager.sharedInstance.centralManager?.connect(peripheral.cbPeripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey : true, CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
    }
    
    // MARK: prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Switch on segue identifier even though there is only one segue
        switch segue.identifier {
        case detailSegueIdentifier:
            // Guard the destination exists and is a PeripheralDetailTableViewController
            guard let vc = segue.destination as? PeripheralDetailTableViewController else { return }
            
            // Set the PeripheralDetailTableViewController variables
            vc.selectedPeripheral = selectedPeripheral
            if let spc = selectedPeripheralCharacteristics {
                vc.selectedPeripheralCharacteristics = spc
            }
            
            // Change the delegate to PeripheralDetailTableViewController so the characteristics can be updated as they are changed
            BluetoothManager.sharedInstance.delegate = vc
            break
        default:
            break
        }
    }
}

// MARK: BluetoothManagerProtocol
extension PeripheralTableViewController {
    func addedNewCharacteristic(characteristic: CBCharacteristic) {
        guard let characteristicValue = characteristic.value,
              let value = String(data: characteristicValue, encoding: .utf8)
        else { return }
        
        // Make new characteristic data and add it to selectedPeripheralCharacteristics
        let characteristicData = CharacteristicData(key: characteristic.uuid.description, value: value)
        selectedPeripheralCharacteristics?.append(characteristicData)
    }
    
    func didConnect(to: CBPeripheral) {
        // Segue after connecting to a peripheral
        performSegue(withIdentifier: detailSegueIdentifier, sender: nil)
    }
    
    func didUpdatePeripherals(peripherals: [CBPeripheral : [String : Any]]) {
        // Peripherals were updated, remove all previous and set new
        discoveredPeripherals.removeAll()
        discoveredPeripherals = peripherals
        
        // Reload the view
        tableView.reloadData()
    }
}
