//
//  UserProfile.swift
//  Networking
//
//  Created by Дарья Выскворкина on 17.01.2021.
//  Copyright © 2021 Alexey Efimov. All rights reserved.
//

import Foundation

struct UserProfile {
    let id: Int?
    let name: String?
    let email: String?
    
    init(data: [String: Any]){
        let id = data["id"] as? Int
        let name = data["name"] as? String
        let email = data["email"] as? String
        self.id = id
        self.name = name
        self.email = email
    }
}
