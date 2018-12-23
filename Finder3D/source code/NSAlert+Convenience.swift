//
//  NSAlert+Convenience.swift
//  Finder3D
//
//  Created by Will Anderson on 12/22/18.
//  Copyright © 2018 Will Anderson. All rights reserved.
//

import Foundation
import AppKit

extension NSAlert {
    
    class func showWith(title:String, message:String){
        
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
        
    }
    
}
