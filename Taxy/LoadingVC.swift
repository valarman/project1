//
//  LoadingVC.swift
//  Taxy
//
//  Created by Artem Valiev on 16.12.15.
//  Copyright © 2015 ltd Elektronnie Tehnologii. All rights reserved.
//

import Foundation
import UIKit

final class LoadingVC: UIViewController, CLLocationManagerDelegate, OnboardingControllerDelegate {
    
    let manager =  CLLocationManager()
    @IBOutlet weak var reloadButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
//        disableMenu()
        title = "Загрузка"
        view.backgroundColor = .lightGrayColor()
        reloadButton.backgroundColor = .mainOrangeColor()
        
        let key = "isNotFirstLoading"
        let def = NSUserDefaults.standardUserDefaults()
        if !def.boolForKey(key) {
            let contr = OnboardingController()
            contr.delegate = self
            presentViewController(contr, animated: false) {}
            def.setBool(true, forKey: key)
        } else {
            checkStatus()
        }
        
    }
    
    deinit {
        manager.delegate = nil
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadButton.layer.cornerRadius = 0.8
        
        
    }
    
    
    private func checkStatus() {
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            GeoSender.instanse.startSending()
            makeRequests()
        case .Restricted, .Denied:
             showGeoError()
        }
    }
    
    
    private func makeRequests() {
        Helper().showLoading("Загрузка городов")
        reloadButton.hidden = true
        Networking.instanse.getCities { [weak self] result in
            Helper().hideLoading()
            self?.reloadButton.hidden = false
            switch result {
            case .Error(let error):
                debugPrint(error)
                Popup.instanse.showError("", message: error)
                
            case .Response(let cities):
                LocalData.instanse.saveCities(cities)

                if let _ = LocalData().getUserID  {
                    Helper().showLoading("Загрузка профиля")
                    self?.reloadButton.hidden = true
                    Networking.instanse.getUserInfo { [weak self] result in
                        self?.reloadButton.hidden = false
                        Helper().hideLoading()
                        switch result {
                        case .Error(let error):
                            Popup.instanse.showError("", message: error)
                            if error == errorDecription().getErrorName(404) { // handle if user not found
                                LocalData.instanse.deleteUserID()
                            }
//                            self?.makeRequests()
                            
                        case .Response(_):
                            if UserProfile.sharedInstance.city?.code == 0 || UserProfile.sharedInstance.city == nil {
                                self?.instantiateSTID(STID.MySettingsSTID)
                            } else {
                                self?.enableMenu()
                                if UserProfile.sharedInstance.type == .Passenger {
                                    self?.instantiateSTID(STID.MakeOrderSTID)
                                } else {
                                    self?.instantiateSTID(STID.FindOrdersSTID)
                                }
                            }
                        }
                    }
                } else {
                    self?.enableMenu()
                    self?.instantiateSTID(STID.LoginSTID)
                }
            }
        }
    }
    

    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            GeoSender.instanse.startSending()
            makeRequests()
        case .Restricted, .Denied:
            showGeoError()
        default:
            break
//        case .NotDetermined:
//            Popup.instanse.showInfo("Включите геолокацию", message: "Для работы приложения, вам необходимо включить геолокацию")
        }
    }
    

    @IBAction func reloadTouched(control: UIControl) {
        checkStatus()
    }
    
    func showGeoError() {
        Popup.instanse.showError("Геолокация выключена", message: "Для работы приложения, вам необходимо включить геолокацию", otherButtons: ["Настройки"]).handler { index in
            if index == 1 {
                UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
            }
        }
    }
    
    func onboardingDismissed() {
       checkStatus()
    }
    
}


class GeoSender: NSObject {
    
    static let instanse = GeoSender()
    var timer: NSTimer?
    
    func startSending() {
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            print("start sending coordinates")
            timer?.invalidate()
            timer = NSTimer.scheduledTimerWithTimeInterval(sendCoordsPeriod, target: self, selector: "sendCoords", userInfo: nil, repeats: true)
            timer!.fire()
        default:
            debugPrint("Error \(__FUNCTION__) \(CLLocationManager.authorizationStatus())")
        }
    }
    
    func sendCoords() {
        Helper().getLocation { result in
            switch result {
            case .Response(let location):
                Networking.instanse.sendCoordinates(location.coordinate)
            default:
                break
            }
        }
    }
    
}