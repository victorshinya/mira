//
//  Mira.swift
//  Minha Historia
//
//  Created by Victor Shinya on 02/05/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import Foundation
import AssistantV1
import CoreLocation

class Mira {
    
    // MARK: - Global vars
    
    private let assistant = Assistant(username: Constants.username, password: Constants.password, version: Constants.version)
    private var context: Context? = nil
    private var delegate: SpeechRecognitionDelegate?
    private lazy var recognition = SpeechRecognition(delegate: delegate!)
    private var voice = VoiceSynthesizer()
    private var finderDelegate: BeaconFinderDelegate?
    private lazy var finder = BeaconFinder(delegate: finderDelegate!)
    
    // MARK: - Initializer
    
    init(delegate: SpeechRecognitionDelegate, finderDelegate: BeaconFinderDelegate) {
        self.delegate = delegate
        self.finderDelegate = finderDelegate
    }
    
    // MARK: - AssistantV1
    
    func update(context: Context) {
        self.context = context
    }
    
    func ask(question: String, completion: @escaping (_ message: String) -> Void) {
        var request = MessageRequest()
        request.input = InputData(text: question)
        request.context = context
        assistant.message(workspaceID: Constants.workspace, request: request, nodesVisitedDetails: false, failure: { error in
            print("[Mira] Error: " + error.localizedDescription)
        }, success: { response in
            self.update(context: response.context)
            let result = response.output.text
            var message = ""
            for i in 0..<result.count { message.append(result[i] + "\n") }
            completion(message)
        })
    }
    
    // MARK: - Speech Recognition
    
    func startRecognition() {
        recognition.start()
    }
    
    func stopRecognition(completion: @escaping (_ message: String) -> Void) {
        let message = recognition.stop()
        ask(question: message) { response in
            completion(response)
        }
    }
    
    func isRuninng() -> Bool {
        return recognition.isRecognizing()
    }
    
    func isAuthorized(completion: @escaping (_ authorized: Bool) -> Void) {
        recognition.requestAuthorization(completion: { authorized in
            completion(authorized)
        })
    }
    
    func isBeaconFinderAuthorized(with delegate: CLLocationManagerDelegate) {
        finder.requestAuthorization(delegate: delegate)
    }
    
    // MARK: - Voice Synthesizer
    
    func speak(message: String) {
        voice.synthesize(message)
    }
    
}
