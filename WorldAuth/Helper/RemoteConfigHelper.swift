//
//  RemoteConfigProvider.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/03/11.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig

/**
 Use this enum to refer the variables that you need to fetch and control remotely
 from Firebase Remote config console.
 */
enum RemoteConfigValueKey: String {
    case authenticationMethod
    case prefersOnDevice
}
/**
 Helper for communicate with firebase remote configs and fetch config values
 */
final class RemoteConfigHelper {
    static let shared = RemoteConfigHelper()
    var loadingDoneCallback: (() -> Void)?
    var fetchComplete = false
    var isDebug = true
    
    private var remoteConfig = RemoteConfig.remoteConfig()
    
    private init() {
        setupConfigs()
        loadDefaultValues()
        setupListener()
    }
    
    func setupConfigs() {
        let settings = RemoteConfigSettings()
        // fetch interval that how frequent you need to check updates from the server
        settings.minimumFetchInterval = isDebug ? 0 : 43200
        remoteConfig.configSettings = settings
    }
    
    /**
     In case firebase failed to fetch values from the remote server due to internet failure
     or any other circumstance, In order to run our application without any issues
     we have to set default values for all the variables that we fetches
     from the remote server.
     */
    func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            RemoteConfigValueKey.authenticationMethod.rawValue: "FGR",
            RemoteConfigValueKey.prefersOnDevice.rawValue: true
        ]
        remoteConfig.setDefaults(appDefaults as? [String: NSObject])
    }
    
    /**
     Setup listner functions for frequent updates
     */
    func setupListener() {
        remoteConfig.addOnConfigUpdateListener { configUpdate, error in
            if let error = error {
                LoggerHelper.logError(
                    parameters: [
                        .message: error.localizedDescription,
                    ]
                )
                return
            }
            
            guard configUpdate != nil else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "REMOTE CONFIG ERROR",
                    ]
                )
                return
            }
            
            self.remoteConfig.activate { changed, error in
                if let error = error {
                    LoggerHelper.logError(
                        parameters: [
                            .message: error.localizedDescription,
                        ]
                    )
                } else {
                    LoggerHelper.logInfo(
                        parameters: [
                            .message: "REMOTE CONFIG activation state change \(changed)",
                        ]
                    )
                }
            }
        }
    }
    
    /**
     Function for fectch values from the cloud
     */
    func fetchCloudValues() {
        remoteConfig.fetch { [weak self] (status, error) -> Void in
            guard let self = self else { return }
            
            if status == .success {
                self.remoteConfig.activate { _, error in
                    if let error = error {
                        LoggerHelper.logError(
                            parameters: [
                                .message: error.localizedDescription,
                            ]
                        )
                        return
                    }
                    self.fetchComplete = true
                    LoggerHelper.logInfo(
                        parameters: [
                            .message: "Remote config fetch success",
                        ]
                    )
                    DispatchQueue.main.async {
                        self.loadingDoneCallback?()
                    }
                }
            } else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Remote config fetch failed",
                    ]
                )
                DispatchQueue.main.async {
                    self.loadingDoneCallback?()
                }
            }
        }
    }
}

// MARK: Basic remote config value access methods

extension RemoteConfigHelper {
    func bool(forKey key: RemoteConfigValueKey) -> Bool {
        return remoteConfig[key.rawValue].boolValue
    }
    
    func string(forKey key: RemoteConfigValueKey) -> String {
        return remoteConfig[key.rawValue].stringValue
    }
    
    func double(forKey key: RemoteConfigValueKey) -> Double {
        return remoteConfig[key.rawValue].numberValue.doubleValue
    }
    
    func int(forKey key: RemoteConfigValueKey) -> Int {
        return remoteConfig[key.rawValue].numberValue.intValue
    }
}

// MARK: Getters for config values

extension RemoteConfigHelper {
    func authenticationMethod() -> String {
        return string(forKey: .authenticationMethod)
    }
    
    func prefersOnDevice() -> Bool {
        return bool(forKey: .prefersOnDevice)
    }
}
