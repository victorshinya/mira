//
//  Mira.swift
//  Minha Historia
//
//  Created by Victor Shinya on 02/05/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import Foundation
import AssistantV1

class Mira {
    
    // MARK: - Global vars
    
    private var assistant = Assistant(username: Constants.username, password: Constants.password, version: Constants.version)
    private var context: Context? = nil
    
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
    
}
