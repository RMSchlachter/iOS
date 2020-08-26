//
//  PeripheralDetailTableViewController.swift
//

import UIKit
import CoreBluetooth

class PeripheralDetailTableViewController: UITableViewController, BluetoothManagerProtocol {

    // MARK: Variables
    var selectedPeripheral: Peripheral? = nil
    var selectedPeripheralCharacteristics = [CharacteristicData]()
    
    var peripheralDetailCellIdenfitier = "PeripheralDetailTableViewCell_identifier"
    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove extra empty cells
        tableView.tableFooterView = UIView()
        
        // No cell selection since it's just data
        tableView.allowsSelection = false
        
        // Set title
        title = selectedPeripheral?.cbPeripheral.name ?? "Details"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Get the peripheral that was connected from Peripheral struct
        guard let peripheral = selectedPeripheral?.cbPeripheral else { return }
        
        // Disconnect from peripheral
        // The delegate is changed back to parent view in its viewWillAppear()
        BluetoothManager.sharedInstance.centralManager?.cancelPeripheralConnection(peripheral)
    }

    // MARK: Table view delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedPeripheralCharacteristics.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: peripheralDetailCellIdenfitier, for: indexPath)

        // Configure the cell
        cell.textLabel?.text = selectedPeripheralCharacteristics[indexPath.row].key
        cell.detailTextLabel?.text = selectedPeripheralCharacteristics[indexPath.row].value

        return cell
    }
}

// MARK: BluetoothManagerProtocol
extension PeripheralDetailTableViewController {
    func addedNewCharacteristic(characteristic: CBCharacteristic) {
        guard let characteristicValue = characteristic.value,
              let value = String(data: characteristicValue, encoding: .utf8)
        else { return }
        
        // Create new characteristic data
        let characteristicData = CharacteristicData(key: characteristic.uuid.description, value: value)
        
        // If selectedPeripheralCharacteristics does not contain the new characteristic, add it and reload the view
        if !selectedPeripheralCharacteristics.contains(where: { $0.key == characteristicData.key })
        {
            selectedPeripheralCharacteristics.append(characteristicData)
            tableView.reloadData()
        }
    }
}
