//
//  LoadingScreen.swift
//  Finder3D
//
//  Created by Will Anderson on 12/20/18.
//  Copyright © 2018 Will Anderson. All rights reserved.
//

import Foundation
import AppKit

class LoadingScreen : NSView {
    
    //MARK: Initializers
    
    override init(frame:CGRect){
        super.init(frame:frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup(){
        isHidden = false
        setBackground()
        addText()
    }
    
    func setBackground(){
        layer = CALayer()
        layer?.backgroundColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 0.7)
    }
    
    func addText(){
        let loadingText = NSTextView(frame: NSRect(x: 0, y: bounds.size.height/2-40, width: bounds.size.width, height: 100))
        loadingText.backgroundColor = NSColor.clear
        loadingText.textColor = NSColor.white
        loadingText.string = "Loading..."
        loadingText.font = NSFont(name: "Courier New", size: 80)
        loadingText.alignCenter(self)
        addSubview(loadingText)
    }
    
    func show(inView view:NSView ,withCompletion completion:@escaping ()->Void){
        
        DispatchQueue.main.async{
            view.addSubview(self)
            completion()
        }
        
    }
    
    func hide(){
        
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
        
    }
    
}
