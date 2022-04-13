//
//  ViewController.swift
//  Notice
//
//  Created by 김태영 on 2022/04/14.
//

import UIKit
import FirebaseRemoteConfig
import FirebaseAnalytics

class ViewController: UIViewController {
    
    var remoteConfig: RemoteConfig?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remoteConfig = RemoteConfig.remoteConfig()
        
        let setting = RemoteConfigSettings()
        setting.minimumFetchInterval = 0
        
        remoteConfig?.configSettings = setting
        remoteConfig?.setDefaults(fromPlist: "RemoteConfigDefaults")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getNotice()
    }


}

extension ViewController {
    func getNotice() {
        guard let remoterConfig = remoteConfig else { return }
        
        remoterConfig.fetch { [weak self] status, _ in
            if status == .success {
                remoterConfig.activate(completion: nil)
            } else {
                print("ERROR: Config not fetched")
            }
            guard let self = self else { return }
            if !self.isNoticeHidden(remoterConfig) {
                let noticeVC = NoticeViewController(nibName: "NoticeViewController", bundle: nil)
                
                noticeVC.modalPresentationStyle = .custom
                noticeVC.modalTransitionStyle = .crossDissolve
                
                let title = (remoterConfig["title"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let detail = (remoterConfig["detail"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let date = (remoterConfig["date"].stringValue ?? "".replacingOccurrences(of: "\\n", with: "\n"))
                
                noticeVC.noticeContents = (title: title, detail: detail, date: date)
                self.present(noticeVC, animated: true, completion: nil)
            } else {
                self.showEventAlert()
            }
        }
    }
    func isNoticeHidden(_ remoteConfig: RemoteConfig) -> Bool {
        return remoteConfig ["isHidden"].boolValue
    }
}

//  A/B Test
extension ViewController {
    func showEventAlert() {
        guard let remoteConfig = remoteConfig else { return }
        
        remoteConfig.fetch { [weak self] status, _ in
            if status == .success {
                remoteConfig.activate(completion: nil)
            } else {
                print("Config not fetched")
            }
            
            let message = remoteConfig["message"].stringValue ?? ""
            let confirmAction = UIAlertAction(title: "확인하기", style: .default) { _ in
                Analytics.logEvent("promotion_Alert", parameters: nil)
            }
            
            let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            let alertController = UIAlertController(title: "깜짝이벤트", message: message, preferredStyle: .alert)
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
}
