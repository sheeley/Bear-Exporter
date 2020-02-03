//
//  BearClient.swift
//  Bear Exporter
//
//  Created by Johnny Sheeley on 2/2/20.
//  Copyright © 2020 Johnny Sheeley. All rights reserved.
//

import Foundation
import CallbackURLKit

class BearClient: Client {
    var token = ""
    
    public init() {
        super.init(urlScheme: "bear")
        
        let manager = Manager.shared
        manager.callbackURLScheme = Manager.urlSchemes?.first
        manager.registerToURLEvent()
    }
    
    func call(_ action: String, params additionalParams: [String:String]? = nil, onSuccess: @escaping SuccessCallback, onFailure: FailureCallback? = nil, onCancel: CancelCallback? = nil) {
        do {
            let params = ["token": token].merging(additionalParams ?? [:]) {(_,new) in new}
            try self.perform(action: action, parameters: params, onSuccess: onSuccess, onFailure: onFailure, onCancel: onCancel)
        } catch {
            onFailure?(UIError(error))
        }
    }
}

struct UIError: FailureCallbackError {
    var code: Int = 0
    var message: String
    
    init(_ err: Error) {
        message = err.localizedDescription
    }
}

