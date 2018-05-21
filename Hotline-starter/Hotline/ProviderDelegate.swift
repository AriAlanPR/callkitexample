//
//  ProviderDelegate.swift
//  Hotline
//
//  Created by MacBook  on 19/05/18.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation
import AVFoundation
import CallKit

class ProviderDelegate: NSObject {
    // 1.
    fileprivate let callManager: CallManager
    fileprivate let provider: CXProvider
    
    init(callManager: CallManager) {
        self.callManager = callManager
        // 2.
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        
        super.init()
        // 3.
        provider.setDelegate(self, queue: nil)
    }
    
    // 4.
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Hotline")
        
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        
        return providerConfiguration
    }
    
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        // 1.
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = hasVideo
        
        // 2.
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                // 3.
                let call = Call(uuid: uuid, handle: handle)
                self.callManager.add(call: call)
            }
            
            // 4.
            completion?(error as? NSError)
        }
    }
}

extension ProviderDelegate: CXProviderDelegate {
    //MARK:- Delegados de CXProvider
    //delegado al reiniciar el proveedor finalizar y limpiar llamadas
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()
        
        for call in callManager.calls {
            call.end()
        }
        
        callManager.removeAllCalls()
    }
    //Acciones del Procider al deslizar para contestar la llamada
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // 1.
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        // 2.
        configureAudioSession()
        // 3.
        call.answer()
        // 4.
        action.fulfill()
    }
    
    // 5.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio()
    }
    //Acciones del provider al colgar la llamada
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // 1.
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        // 2.
        stopAudio()
        // 3.
        call.end()
        // 4.
        action.fulfill()
        // 5.
        callManager.remove(call: call)
    }
}


