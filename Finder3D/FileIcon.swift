//
//  FileIcon.swift
//  Finder3D
//
//  Created by Will Anderson on 12/17/18.
//  Copyright © 2018 Will Anderson. All rights reserved.
//

import Foundation
import SceneKit

class FileIcon{
    
    var node:SCNNode
    var name:String
    
    init(name:String,node:SCNNode){
        self.name = name
        self.node = node
    }
    
}
