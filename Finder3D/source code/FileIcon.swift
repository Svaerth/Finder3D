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
    
    //MARK: constants
    let MAX_FILENAME_LENGTH:Int = 15
    let ICON_HIGHLIGHT_OPACITY:CGFloat = 0.3
    
    //the file icon node that all file icon nodes will be created from
    private static let prototypeFileIconNode:SCNNode = SCNScene(named: "art.scnassets/fileIcon.scn")!.rootNode.childNode(withName: "FileIcon", recursively: true)!
    
    var node:SCNNode
    var name:String
    
    //MARK: public methods
    
    init(fileName:String, directoryPath:String, x:Float, y:Float, z:Float){
        
        name = fileName
        node = FileIcon.prototypeFileIconNode.clone()
        setPosition(x:x,y:y,z:z)
        setImageToIconOfFileAt(path:directoryPath+"/"+name)
        setFileIconName()
        hideHighlight()
        
    }
    
    func showHighlight(){
        setHighlightOpacity(to:ICON_HIGHLIGHT_OPACITY)
    }
    
    func hideHighlight(){
        setHighlightOpacity(to: 0)
    }
    
    
    //MARK: private methods
    
    private func setPosition(x:Float, y:Float, z:Float){
        node.simdPosition.x = x
        node.simdPosition.y = y
        node.simdPosition.z = z
    }
    
    private func setImageToIconOfFileAt(path filePath:String){
        
        if let iconNode = node.childNode(withName: "Icon", recursively: true){
            let iconImage = NSWorkspace.shared.icon(forFile: filePath)
            iconNode.geometry = iconNode.geometry?.copy() as? SCNGeometry
            iconNode.geometry?.firstMaterial = iconNode.geometry?.firstMaterial?.copy() as? SCNMaterial
            iconNode.geometry?.firstMaterial?.diffuse.contents = iconImage
            iconNode.geometry?.firstMaterial?.emission.contents = iconImage
        }
        
    }
    
    private func setFileIconName(){
        
        if let labelNode = node.childNode(withName: "Label", recursively: true), let text = labelNode.geometry?.copy() as? SCNText{
            labelNode.geometry = text
            if name.count > self.MAX_FILENAME_LENGTH{
                text.string = self.getTruncatedVersionOf(name,maxLength: MAX_FILENAME_LENGTH)
            }else{
                text.string = name
            }
        }
        
    }
    
    private func getTruncatedVersionOf(_ string:String, maxLength:Int) -> String{
        
        let nsString = string as NSString
        var truncatedString = nsString.substring(to: maxLength - 3)
        truncatedString += "..."
        return truncatedString
        
    }
    
    private func setHighlightOpacity(to opacity:CGFloat){
        if let highlight = node.childNode(withName: "Highlight", recursively: true){
            highlight.opacity = opacity
        }
    }
    
}
