//
//  CurrentUser.swift
//  Networking
//
//  Created by Дарья Выскворкина on 17.01.2021.
//  Copyright © 2021 Alexey Efimov. All rights reserved.
//

import Foundation

struct CurrentUser{
    let uid: String
    let name: String
    let email: String
    
    init?(uid: String, data: [String: Any]){
        guard let name = data["name"] as? String,
              let email = data["email"] as? String
        else {
            return nil
        }
        self.uid = uid
        self.email = email
        self.name = name
    }
}
