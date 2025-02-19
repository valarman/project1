//
//  EnterPhoneVC.swift
//  Taxy
//
//  Created by iosdev on 27.11.15.
//  Copyright © 2015 ltd Elektronnie Tehnologii. All rights reserved.
//

import Foundation
import UIKit
import DrawerController
import Former

enum RowType: Int {
    case Phone
    case Pincode
}


final class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Public
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "phoneFieldChanged:", name: "phoneNotification", object: nil)
        
        title = "Добро пожаловать!"
        tableView.separatorStyle = .None
        disableMenu()
        switchInfomationSection(.Phone)
        configure()
        updateView()
        //goAhead()
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func phoneFieldChanged(notif: NSNotification) {
        guard notif.name == "phoneNotification", let phoneStr = notif.object as? String else {
            return
        }
        phone = phoneStr
        updateView()
    }
    
    
    // MARK: Private
//    private var loginInfo = Login()
    var phone = ""
    var pincode = ""
    private lazy var former: Former = Former(tableView: self.tableView)
    private var getSmsButtonRow: LabelRowFormer<CenterLabelCell>?
    
    @IBOutlet private weak var tableView: UITableView!
    
    
    private lazy var phoneSection: SectionFormer = {
        
        let descriptionHeader = LabelViewFormer<FormLabelHeaderView>() {
            $0.contentView.backgroundColor = .clearColor()
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.textAlignment = .Center
            $0.titleLabel.font = .light_Lar()
            }
            .configure {
                $0.viewHeight = 60
                $0.text = "Введите номер телефона"
        }
        
        
        let phoneRow = PhoneRowFormer<PhoneCell>(instantiateType: .Nib(nibName: "PhoneCell")) {
            $0.phoneTextField.keyboardType = .DecimalPad
            }
//            .onTextChanged { [weak self] in
//                self?.loginInfo.phone = $0
//                self?.updateView()
//        }

        
        
        return SectionFormer(rowFormer: phoneRow).set(headerViewFormer: descriptionHeader)
    }()
    
    
    private lazy var pincodeSection: SectionFormer = {
        
        let descriptionHeader = LabelViewFormer<FormLabelHeaderView>() {
            $0.contentView.backgroundColor = .clearColor()
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.textAlignment = .Center
             $0.titleLabel.font = .light_Lar()
            }
            .configure {
                $0.viewHeight = 60
                $0.text = "Введите код, полученный по СМС"
        }
        
        
        let pincodeRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "СМС код"
            $0.textField.keyboardType = .DecimalPad
            }.configure {
                $0.placeholder = "Введите код"
            }.onTextChanged { [weak self] in
                self?.pincode = $0
                self?.updateView()
        }
        
        return SectionFormer(rowFormer: pincodeRow).set(headerViewFormer: descriptionHeader)
    }()
    
    
    private lazy var noSMSSection: SectionFormer = {
        let phoneRow = LabelRowFormer<CenterLabelCell>() {
            $0.contentView.backgroundColor = .clearColor()
            $0.backgroundColor = .clearColor()
            $0.titleLabel.textColor = .whiteColor()
            $0.selectionStyle = .None
            }.configure {
                $0.text = "Не пришло СМС?"
            }.onSelected { [weak self] _ in
                
                guard let phone = self?.phone where self?.phone.characters.count > 0  else {
                    return
                }
                let numberPhone = phone.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
                
                Popup.instanse.showQuestion(phone, message: "Отправить СМС заново?", otherButtons: ["Отправить"], cancelButtonTitle: "Отмена").handler { selectedIndex in
                    if selectedIndex == 1 {
                        Networking.instanse.getSms(numberPhone) { [weak self] result in
                            switch result {
                            case .Error(let error):
                                Popup.instanse.showError("", message: error)
                            default:
                                break
                            }
                            
                        }
                    }
                }
        }
        
        let createSpaceHeader: (() -> ViewFormer) = {
            return CustomViewFormer<FormHeaderFooterView>() {
                $0.contentView.backgroundColor = .clearColor()
                }.configure {
                    $0.viewHeight = 10
            }
        }
        return SectionFormer(rowFormer: phoneRow).set(headerViewFormer: createSpaceHeader())
    }()
    
    
    private func configure() {
        tableView.backgroundColor = .formerColor()
        tableView.layer.cornerRadius = 5
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        
        
        
        let getSmsButtonRow = LabelRowFormer<CenterLabelCell>()
            .onSelected { [weak self] _ in
                
                guard let phone = self?.phone else {
                    return
                }
                let numberPhone = phone.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
                
                if self?.former.firstSectionFormer === self?.phoneSection {

                        self?.view.endEditing(true)
                        Popup.instanse.showQuestion(phone, message: "Отправить СМС на указанный номер?", otherButtons: ["Отправить"], cancelButtonTitle: "Отмена").handler { [weak self] selectedIndex in
                            if selectedIndex == 1 {
                                Helper().showLoading("Отправляем СМС")
                                Networking().getSms(numberPhone) { [weak self] result in
                                    Helper().hideLoading()
                                    switch result {
                                    case .Error(let error):
                                        Popup.instanse.showError("", message: error)
                                    case .Response(_):
//                                        self?.loginInfo.id = data
                                        self?.switchInfomationSection(.Pincode)
                                        self?.updateView()
                                    }
                                }
                            }
                    }
                } else {
                    Helper().showLoading()
                    
                    guard let pinCode = self?.pincode else { return }
                    
                    Networking().checkPincode(numberPhone, pinCode: pinCode) { [weak self] result in
                        Helper().hideLoading()

                        switch result {
                        case .Error(let error):
                            Popup.instanse.showError("", message: error)
                        case .Response(let data):
                            LocalData.instanse.saveUserID(data)
                            self?.goAhead()
                        }
                        
                    }
                }
        }
        
        self.getSmsButtonRow = getSmsButtonRow
        
        let createSpaceHeader: (() -> ViewFormer) = {
            return CustomViewFormer<FormHeaderFooterView>() {
                $0.contentView.backgroundColor = .clearColor()
                }.configure {
                    $0.viewHeight = 30
            }
        }
        let buttonSection = SectionFormer(rowFormer: getSmsButtonRow)
            .set(headerViewFormer: createSpaceHeader())
        
        former.append(sectionFormer: buttonSection)
    }
    
    
    
    private func updateView() {
        if former.firstSectionFormer === phoneSection {
            if let row = phoneSection.firstRowFormer as? TextFieldRowFormer<FormTextFieldCell> {
                let enabled = !(row.text?.isEmpty ?? true)
                getSmsButtonRow?.enabled = enabled
            }
            getSmsButtonRow?.text = "Получить СМС"
            getSmsButtonRow?.update()
        } else {
            if let row = pincodeSection.firstRowFormer as? TextFieldRowFormer<ProfileFieldCell> {
                let enabled = !(row.text?.isEmpty ?? true)
                getSmsButtonRow?.enabled = enabled
            }
            getSmsButtonRow?.text = "Отправить код"
            getSmsButtonRow?.update()
        }
        
        //        if let pincodeRow = pincodeSection.firstRowFormer as? TextFieldRowFormer<ProfileFieldCell> {
        //            pincodeRow.update()
        //        }
    }
    
    
    
    private func switchInfomationSection(currentRow: RowType) {
        switch currentRow {
        case .Phone:
            former.insertUpdate(sectionFormer: phoneSection, toSection: 0, rowAnimation: .Top)
            former.removeUpdate(sectionFormer: pincodeSection)
            former.removeUpdate(sectionFormer: noSMSSection)
            
        case .Pincode:
            former.insertUpdate(sectionFormer: pincodeSection, toSection: 0, rowAnimation: .Top)
            former.insertUpdate(sectionFormer: noSMSSection, toSection: former.numberOfSections)
            former.removeUpdate(sectionFormer: phoneSection)
        }
    }
    
    
    private func goAhead() -> Void {
        instantiateSTID(STID.MySettingsSTID)
    }
    
    
    
}
