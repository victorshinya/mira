//
//  ViewController.swift
//  Minha História
//
//  Created by Victor Shinya on 28/04/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import UIKit
import Speech
import CoreLocation

class ViewController: UIViewController, SFSpeechRecognizerDelegate, CLLocationManagerDelegate {
    
    // MARK: - Global vars
    
    private var mira = Mira()
    private var message = ""
    
    private let speechRecognizer = SFSpeechRecognizer.init(locale: Locale.init(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var locationManager: CLLocationManager!
    private var runOnlyOnce = false
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - IBOutlets

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var output: UILabel!
    @IBOutlet weak var firstInteraction: UIView!
    
    // MARK: - Lifecycle events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Remove after tests
        firstInteraction.removeFromSuperview()
        self.record.isHidden = false
        setUpUI()
        setDelegates()
        setUpLocationManager()
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            record.isEnabled = true
        } else {
            record.isEnabled = false
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }
    
    // MARK: - Custom methods
    
    func setUpUI() {
        record.layer.cornerRadius = record.layer.frame.size.height / 2
        record.clipsToBounds = true
    }
    
    func setDelegates() {
        speechRecognizer?.delegate = self
    }
    
    func setUpSpeechRecognizer() {
        SFSpeechRecognizer.requestAuthorization { status in
            var isEnabled = false
            switch status {
            case .notDetermined:
                print("Speech Recognition not yet authorized")
            case .denied:
                print("User denied access to Speech Recognition")
            case .restricted:
                print("Speech Recognition restricted on this device")
            case .authorized:
                isEnabled = true
            }
            OperationQueue.main.addOperation {
                self.record.isEnabled = isEnabled
            }
        }
    }
    
    func startRecognizing() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("An error has occured")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil, let text = result?.bestTranscription.formattedString, let final = result?.isFinal {
                print("Recognized audio: " + text)
                isFinal = final
                self.message = text
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.record.isEnabled = true
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.stop()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine object could not started")
        }
        print("Audio recording started")
    }
    
    func stopRecognizing() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        try? audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
        try? audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        mira.ask(question: message) { response in
            DispatchQueue.main.async {
                self.output.text = response
            }
        }
    }
    
    func setUpLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: Constants.uuid)!
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 13, minor: 1, identifier: "MyBeacon")
        
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func update(distance: CLProximity) {
        UIView.animate(withDuration: 0.8) {
            switch distance {
            case .unknown:
                print("Unknown")
            case .far:
                print("Far away (more than 10 meters)")
            case .immediate:
                print("Beacon so close")
            case .near:
                print("Nearby")
                if (!self.runOnlyOnce) {
                    self.mira.ask(question: "") { response in
                        DispatchQueue.main.async {
                            self.output.text = response
                        }
                    }
                    self.runOnlyOnce = true
                    self.firstInteraction.removeFromSuperview()
                    self.record.isHidden = false
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            let beacon = beacons[0]
            update(distance: beacon.proximity)
        } else {
            update(distance: .unknown)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Fail while monitoring: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Fail on Location Manager: \(error.localizedDescription)")
    }
    
    func speak(text: String) {
        self.output.text = text
        let speechUtterance = AVSpeechUtterance(string: self.output.text!)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        speechSynthesizer.speak(speechUtterance)
    }
    
    func extractURL(from text: String) -> String {
        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try? NSDataDetector(types: types.rawValue)
        guard let detect = detector else {
            return ""
        }
        let matches = detect.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
        for match in matches {
            return match.url!.absoluteString
        }
        return ""
    }
    
    // MARK: - IBAction

    @IBAction func recordTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            stopRecognizing()
            record.isEnabled = false
            record.setImage(UIImage(named: "ic_mic"), for: .normal)
        } else {
            startRecognizing()
            record.setImage(UIImage(named: "ic_stop"), for: .normal)
        }
    }
}
