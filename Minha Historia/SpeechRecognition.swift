//
//  SpeechRecognition.swift
//  Minha Historia
//
//  Created by Victor Shinya on 02/05/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import Foundation
import Speech

class SpeechRecognition: NSObject, SFSpeechRecognizerDelegate {
    
    // MARK: - Global vars
    
    public var delegate: SpeechRecognitionDelegate?
    private var recognized: String?
    
    private lazy var speechRecognizer = SFSpeechRecognizer.init(locale: Locale.init(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initialize
    
    init(delegate: SpeechRecognitionDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        delegate?.isSpeechRecognition(available)
    }
    
    // MARK: - SFSpeechRecognizer
    
    func requestAuthorization(completion: @escaping (_ authorized: Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            var isAuthorized = false
            switch status {
            case .notDetermined:
                print("[Speech Recognition] Error: Speech Recognition not yet authorized")
                isAuthorized = false
            case .denied:
                print("[Speech Recognition] Error: User denied access to Speech Recognition")
                isAuthorized = false
            case .restricted:
                print("[Speech Recognition] Error: Speech Recognition restricted on this device")
                isAuthorized = false
            case .authorized:
                print("[Speech Recognition] Authorized")
                isAuthorized = true
            }
            completion(isAuthorized)
        }
    }
    
    func start() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("[Speech Recognition] Error: While configuring Audio Session to start recognizing speech")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        recognitionRequest?.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!, resultHandler: { result, error in
            if result != nil, let text = result?.bestTranscription.formattedString {
                print("[Speech Recognition] Audio: \(text)")
                self.recognized = text
            }
            if error != nil || (result?.isFinal)! {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("[Speech Recognition] Audio: Audio recording started")
        } catch {
            print("[Speech Recognition] Error: Audio engine object could not started")
        }
    }
    
    func stop() -> String {
        audioEngine.stop()
        audioEngine.reset()
        recognitionRequest?.endAudio()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
            try audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            print("[Speech Recognition] Error: While configuring Audio Session to stop recognizing speech")
        }
        return recognized ?? ""
    }
    
    func isRecognizing() -> Bool {
        return audioEngine.isRunning
    }
    
}

protocol SpeechRecognitionDelegate {
    func isSpeechRecognition(_ available: Bool)
}
