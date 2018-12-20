//
//  GameViewController.swift
//  Finder3D
//
//  Created by Will Anderson on 12/15/18.
//  Copyright © 2018 Will Anderson. All rights reserved.
//

import SceneKit
import QuartzCore

class GameViewController: NSViewController  ,  SCNSceneRendererDelegate{

    //MARK: CONSTANTS
    let ROW_SIZE = 10
    let ICON_SPACING = 15
    let ICON_HIGHLIGHT_OPACITY:CGFloat = 0.3
    let INITIAL_DISTANCE_FROM_CAMERA = 50
    let MAX_FILENAME_LENGTH = 15
    let INTERACTION_DISTANCE:Float = 10
    
    //MARK: keyboard variables
    var upArrowPressed:Bool = false
    var downArrowPressed:Bool = false
    var leftArrowPressed:Bool = false
    var rightArrowPressed:Bool = false
    var spaceBarPressed:Bool = false
    var backSpacePressed:Bool = false
    
    //MARK: movement variables
    var speed:Float = 0
    var rotation:Float = 0
    
    var camera:SCNNode! = nil
    var scene:SCNScene! = nil
    var scnView:SCNView! = nil
    
    let fileIconScene = SCNScene(named: "art.scnassets/fileIcon.scn")!
    var fileIconNode:SCNNode! = nil
    
    //MARK: Directory variables
    var currentDirectoryPath:String = ""
    var fileIcons:[FileIcon] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fileIconNode = fileIconScene.rootNode.childNode(withName: "FileIcon", recursively: true)!
        
        setupScene()
        camera = scene.rootNode.childNode(withName: "camera", recursively: true)
        open(directory: NSHomeDirectory())
        
        
    }
    
    func getTruncatedVersionOf(_ string:String) -> String{
        
        let nsString = string as NSString
        var truncatedString = nsString.substring(to: MAX_FILENAME_LENGTH - 3)
        truncatedString += "..."
        return truncatedString
        
    }
    
    func open(directory:String){
        
        DispatchQueue.main.async{
        
            self.showLoadingGraphic()
            
            //loading new directory on background thread
            DispatchQueue.global(qos: .userInitiated).async{
            
                self.currentDirectoryPath = directory
                
                self.removeFileNodesFromScene()
                
                self.fileIcons = []
                
                do {
                    let filesInCurrentDirectory = try FileManager.default.contentsOfDirectory(atPath: self.currentDirectoryPath)
                    
                    var n:Int = 0
                    for file in filesInCurrentDirectory{
                        
                        //loading the node
                        let fileIconNodeClone = self.fileIconNode.clone()
                        
                        self.scene.rootNode.addChildNode(fileIconNodeClone)
                        
                        self.fileIcons.append(FileIcon(name:file,node:fileIconNodeClone))
                        
                        //setting the position
                        if filesInCurrentDirectory.count >= 10{
                            fileIconNodeClone.simdPosition.x = Float(n % self.ROW_SIZE * self.ICON_SPACING) - Float(self.ICON_SPACING * (self.ROW_SIZE/2))
                        }else{
                            fileIconNodeClone.simdPosition.x = Float( -1 * ( (filesInCurrentDirectory.count-1) * self.ICON_SPACING)/2 + n * self.ICON_SPACING)
                        }
                        fileIconNodeClone.simdPosition.z = -1 * Float(n / self.ROW_SIZE * self.ICON_SPACING) - Float(self.INITIAL_DISTANCE_FROM_CAMERA)
                        fileIconNodeClone.simdPosition.y = self.camera.simdPosition.y
                        
                        //setting the file icon
                        if let iconNode = fileIconNodeClone.childNode(withName: "Icon", recursively: true){
                            let iconImage = NSWorkspace.shared.icon(forFile: self.currentDirectoryPath+"/"+file)
                            iconNode.geometry = iconNode.geometry?.copy() as? SCNGeometry
                            iconNode.geometry?.firstMaterial = iconNode.geometry?.firstMaterial?.copy() as? SCNMaterial
                            iconNode.geometry?.firstMaterial?.diffuse.contents = iconImage
                            iconNode.geometry?.firstMaterial?.emission.contents = iconImage
                        }
                        
                        //setting the filename
                        if let labelNode = fileIconNodeClone.childNode(withName: "Label", recursively: true), let text = labelNode.geometry?.copy() as? SCNText{
                            labelNode.geometry = text
                            if file.count > self.MAX_FILENAME_LENGTH{
                                text.string = self.getTruncatedVersionOf(file)
                            }else{
                                text.string = file
                            }
                        }
                        
                        //hiding the highlight box
                        if let highlightNode = fileIconNodeClone.childNode(withName: "Highlight", recursively: true){
                            highlightNode.opacity = 0
                        }
                        
                        n += 1
                    }
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                
                self.resetCamera()
                
                self.removeLoadingGraphic()
                
            }
            
        }
        
    }
    
    var loadingView:NSView? = nil
    
    func showLoadingGraphic(){
        
        scnView.isPlaying = false
        
        if loadingView == nil{
            loadingView = NSView(frame: self.view.bounds)
            loadingView?.layer = CALayer()
            loadingView?.layer?.backgroundColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 0.7)
            loadingView?.isHidden = false
            let loadingText = NSTextView(frame: NSRect(x: 0, y: loadingView!.bounds.size.height/2-40, width: loadingView!.bounds.size.width, height: 100))
            loadingText.backgroundColor = NSColor.clear
            loadingText.textColor = NSColor.white
            loadingText.string = "Loading..."
            loadingText.font = NSFont(name: "Courier New", size: 80)
            loadingText.alignCenter(self)
            loadingView?.addSubview(loadingText)
        }
        self.view.addSubview(self.loadingView!)
        
    }
    
    func removeLoadingGraphic(){
        DispatchQueue.main.async {
            self.loadingView?.removeFromSuperview()
            self.scnView.isPlaying = true
        }
    }
    
    func removeFileNodesFromScene(){
        for fileIcon in fileIcons{
            fileIcon.node.removeFromParentNode()
        }
    }
    
    func resetCamera(){
        camera.simdPosition.x = 0
        camera.simdPosition.z = 0
        camera.eulerAngles.x = 0
        camera.eulerAngles.y = -0
        camera.eulerAngles.z = 0
    }
    
    func setupScene(){
        scene = SCNScene(named: "art.scnassets/main.scn")!
        scnView = self.view as? SCNView
        scnView.scene = scene
        scnView.delegate = self
        scnView.loops = true
        scnView.isPlaying = true
        
    }
    
    func goToParentDirectory(){
        
        let currentDirectoryNSString = currentDirectoryPath as NSString
        if let urlFriendlyDirectoryPath = currentDirectoryNSString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed), let currentDirectoryURL = URL(string: urlFriendlyDirectoryPath){
            let parentDirectoryURL = currentDirectoryURL.deletingLastPathComponent()
            let parentDirectory = parentDirectoryURL.path
        
            //if the parent directory points to an actual directory
            var isDirectory:ObjCBool = ObjCBool(false)
            if FileManager.default.fileExists(atPath: parentDirectory, isDirectory: &isDirectory) && isDirectory.boolValue == true{
                open(directory: parentDirectory)
            }
        
        }
            
    }
    
    //MARK: game loop
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval){
        
        processArrowKeyInput()
        
        move()
        
        var selectedFileIcon:FileIcon? = nil
        var selectedFileNodeDistance:Float = -1
        for fileIcon in fileIcons{
            let deltaX = camera.simdPosition.x - fileIcon.node.simdPosition.x
            let deltaZ = camera.simdPosition.z - fileIcon.node.simdPosition.z
            let distance = sqrt(deltaX*deltaX + deltaZ*deltaZ)
            if distance < INTERACTION_DISTANCE && (distance < selectedFileNodeDistance || selectedFileIcon == nil){
                selectedFileIcon = fileIcon
                selectedFileNodeDistance = distance
            }
            
            //hiding the highlight to make sure that it doesn't get left on
            if let highlight = fileIcon.node.childNode(withName: "Highlight", recursively: true){
                highlight.opacity = 0
            }
        }
        
        //highlighting the selected file node
        if let highlight = selectedFileIcon?.node.childNode(withName: "Highlight", recursively: true){
            highlight.opacity = ICON_HIGHLIGHT_OPACITY
        }
        
        if spaceBarPressed {
            spaceBarPressed = false
            if let selectedFileName = selectedFileIcon?.name{
                let filePath = currentDirectoryPath+"/"+selectedFileName
                var isDirectory:ObjCBool = ObjCBool(false)
                _ = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
                if isDirectory.boolValue == true{
                    open(directory:filePath)
                }else{
                    NSWorkspace.shared.openFile(filePath)
                }
            }
        }
        
        if backSpacePressed {
            backSpacePressed = false
            goToParentDirectory()
        }
        
    }
    
    func make(_ node2Rotate:SCNNode, faceTowards targetNode:SCNNode){
        
        let deltaX = targetNode.simdPosition.x - node2Rotate.simdPosition.x
        let deltaZ = targetNode.simdPosition.z - node2Rotate.simdPosition.z
        node2Rotate.eulerAngles.y = atan2(CGFloat(deltaX), CGFloat(deltaZ))
        
    }
    
    func processArrowKeyInput(){
        
        if leftArrowPressed{
            //rotating to the left
            camera.simdEulerAngles.y += 0.05
        }
        if rightArrowPressed{
            //rotating to the right
            camera.simdEulerAngles.y -= 0.05
        }
        
        if upArrowPressed && downArrowPressed{
            speed = 0
        }else if upArrowPressed{
            speed = -0.3
        }else if downArrowPressed{
            speed = 0.3
        }else{
            speed = 0
        }
        
        move()
        
    }
    
    func move(){
        
        camera.simdPosition.x += sin(camera.simdEulerAngles.y) * Float(speed)
        camera.simdPosition.z += cos(camera.simdEulerAngles.y) * Float(speed)
        
    }
    
    override func keyDown(with event: NSEvent){
        
        switch(event.keyCode){
        case LEFT_ARROW_KEY_CODE:
            leftArrowPressed = true
        case RIGHT_ARROW_KEY_CODE:
            rightArrowPressed = true
        case UP_ARROW_KEY_CODE:
            upArrowPressed = true
        case DOWN_ARROW_KEY_CODE:
            downArrowPressed = true
        case SPACE_BAR_KEY_CODE:
            spaceBarPressed = true
        case BACKSPACE_KEY_CODE:
            backSpacePressed = true
        default:
            break
        }
        
    }
    
    override func keyUp(with event: NSEvent){
        
        switch(event.keyCode){
        case LEFT_ARROW_KEY_CODE:
            leftArrowPressed = false
        case RIGHT_ARROW_KEY_CODE:
            rightArrowPressed = false
        case UP_ARROW_KEY_CODE:
            upArrowPressed = false
        case DOWN_ARROW_KEY_CODE:
            downArrowPressed = false
        default:
            break
        }
        
    }
    
}
