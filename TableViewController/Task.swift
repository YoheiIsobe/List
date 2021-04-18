//
//  Task.swift
//  TableViewController
//
//  Created by Nechan on 2020/02/03.
//  Copyright © 2020 Nechan. All rights reserved.
//

import UIKit
import RealmSwift

class Task: Object {
    @objc dynamic var id = 0
    
    @objc dynamic var date = Date()
    
    @objc dynamic var text = ""
    
    @objc dynamic var check = false
}
