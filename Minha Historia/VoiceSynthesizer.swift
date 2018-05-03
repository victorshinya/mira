//
//  VoiceSynthesizer.swift
//  Minha Historia
//
//  Created by Victor Shinya on 02/05/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import Foundation
import Speech

class VoiceSynthesizer {
    
    // MARK: - Global vars
    
    private lazy var speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - AVSpeechUtterance and AVSpeechSynthesisVoice
    
    func synthesize(_ message: String) {
        let speechUtterance = AVSpeechUtterance(string: message)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: Constants.language)
        speechSynthesizer.speak(speechUtterance)
    }
}
