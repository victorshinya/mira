//
//  ViewController.swift
//  Minha História
//
//  Created by Victor Shinya on 28/04/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, SpeechRecognitionDelegate, BeaconFinderDelegate, CLLocationManagerDelegate {
    
    // MARK: - Global vars
    
    private lazy var mira = Mira(delegate: self, finderDelegate: self)
    private var message = ""
    
    // MARK: - IBOutlets

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var output: UILabel!
    @IBOutlet weak var firstInteraction: UIView!
    
    // MARK: - Lifecycle events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set Up User Interface
        record.layer.cornerRadius = record.layer.frame.size.height / 2
        record.clipsToBounds = true
        // Request User Authorization
        mira.isBeaconFinderAuthorized(with: self)
        mira.isAuthorized(completion: { authorized in
            DispatchQueue.main.async {
                self.record.isEnabled = authorized
            }
        })
    }
    
    // MARK: - SpeechRecognitionDelegate
    
    func isSpeechRecognition(_ available: Bool) {
        record.isEnabled = available
    }
    
    // MARK: - BeaconFinderDelegate
    
    func updateBeaconFinder() {
        mira.ask(question: "") { response in
            DispatchQueue.main.async {
                self.output.text = response
            }
        }
        firstInteraction.removeFromSuperview()
        record.isHidden = false
    }
    
    // MARK: - Other functions
    
    func speak(text: String) {
        self.output.text = text
        mira.speak(message: text)
    }
    
    // MARK: - IBAction

    @IBAction func recordTapped(_ sender: UIButton) {
        if mira.isRuninng() {
            mira.stopRecognition { message in
                DispatchQueue.main.async {
                    self.speak(text: message)
                }
            }
            record.setImage(UIImage(named: "ic_mic"), for: .normal)
        } else {
            mira.startRecognition()
            record.setImage(UIImage(named: "ic_stop"), for: .normal)
        }
    }
}
