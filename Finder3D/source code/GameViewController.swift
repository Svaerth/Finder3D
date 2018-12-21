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

    //MARK: constants
    let MAX_ICONS_IN_ROW = 10
    let SPACE_BETWEEN_ROWS = 15
    let SPACE_BETWEEN_COLUMNS = 15
    let ICON_HIGHLIGHT_OPACITY:CGFloat = 0.3
    let INITIAL_DISTANCE_FROM_CAMERA:Float = 50
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
    
    //MARK: scene object variables
    var camera:SCNNode! = nil
    var scene:SCNScene! = nil
    var scnView:SCNView! = nil
    
    //MARK: Directory variables
    var currentDirectoryPath:String = ""
    var fileIcons:[FileIcon] = []
    
    //MARK: Loading Screen
    var loadingScreen:LoadingScreen! = nil
    
    //MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingScreen = LoadingScreen(frame: self.view.bounds)
        setupScene()
        camera = getReferenceToCamera()
        load(directory: NSHomeDirectory())
        
    }
    
    func getReferenceToCamera() -> SCNNode {
        return scene.rootNode.childNode(withName: "camera", recursively: true)!
    }
    
    func load(directory newDirectory:String){
        
        loadingScreen.show(inView: self.view, withCompletion:{
            
            //loading new directory on background thread
            DispatchQueue.global(qos: .userInitiated).async{
                
                self.currentDirectoryPath = newDirectory
                
                self.removeFileNodesFromScene()
                
                self.fileIcons = []
                
                do {
                    let filesInCurrentDirectory = try FileManager.default.contentsOfDirectory(atPath: self.currentDirectoryPath)
                    self.fileIcons = self.createFileIconsFor(files: filesInCurrentDirectory)
                    self.addFileIconsToScene(fileIcons: self.fileIcons)
                }
                catch let error as NSError {
                    self.show(error: error, forLoadingDirectory: self.currentDirectoryPath)
                }
                
                self.resetCamera()
                
                self.loadingScreen.hide()
                
            }
            
        })
        
    }
    
    func show(error: NSError, forLoadingDirectory directory:String){
        let alert = NSAlert()
        alert.messageText = "Directory Load Error"
        alert.informativeText = "Ooops! Something went wrong while loading directory \(directory): \(error)"
        alert.runModal()
    }
    
    func createFileIconsFor(files:[String]) -> [FileIcon]{
        
        var fileIcons:[FileIcon] = []
        var i:Int = 0
        for file in files{
            
            let newFileIconPosition = self.calculatePositionForFileIconAt(positionInLine: i, withTotalFilesToShow: files.count)
            let newFileIcon = FileIcon(fileName:file, directoryPath:self.currentDirectoryPath, x:newFileIconPosition.x, y:newFileIconPosition.y, z:newFileIconPosition.z)
            fileIcons.append(newFileIcon)
            
            i += 1
            
        }
        
        return fileIcons
        
    }
    
    func addFileIconsToScene(fileIcons:[FileIcon]){
        for fileIcon in fileIcons{
            self.scene.rootNode.addChildNode(fileIcon.node)
        }
    }
    
    func calculatePositionForFileIconAt(positionInLine:Int, withTotalFilesToShow totalFilesToShow:Int) -> (x:Float, y:Float, z:Float){
        
        var x:Float = 0
        var y:Float = 0
        var z:Float = 0
        
        //when there are a number of files greater than or equal to ROW_SIZE we arrange them in rows of length equal to ROW_SIZE
        if totalFilesToShow >= MAX_ICONS_IN_ROW{
            
            //calculate x position
            let leftMostPosition = -1 * Float(self.SPACE_BETWEEN_COLUMNS * (self.MAX_ICONS_IN_ROW/2))
            let column = positionInLine % self.MAX_ICONS_IN_ROW
            let spaceFromLeft = Float(column * self.SPACE_BETWEEN_COLUMNS)
            x = leftMostPosition + spaceFromLeft
            
            //calculate z position
            let row = positionInLine / self.MAX_ICONS_IN_ROW
            let distanceFromCamera = self.INITIAL_DISTANCE_FROM_CAMERA + Float(row * self.SPACE_BETWEEN_ROWS)
            z = -1 * distanceFromCamera
            
        }
        //when there are fewer than ROW_SIZE files to show, we make one row and center it in front of the user
        else{
            
            //calculate x position
            let rowWidth = (totalFilesToShow-1) * self.SPACE_BETWEEN_COLUMNS
            let leftMostPosition = -1 * rowWidth/2
            let spaceFromLeft = positionInLine * self.SPACE_BETWEEN_COLUMNS
            x = Float(leftMostPosition + spaceFromLeft)
            
            z = -1 * self.INITIAL_DISTANCE_FROM_CAMERA
            
        }
        
        y = self.camera.simdPosition.y
        
        return (x:x,y:y,z:z)
        
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
    
        //if the parent directory points to an actual directory
        let parentDirectory = (currentDirectoryPath as NSString).deletingLastPathComponent
        var isDirectory:ObjCBool = ObjCBool(false)
        if FileManager.default.fileExists(atPath: parentDirectory, isDirectory: &isDirectory) && isDirectory.boolValue == true{
            load(directory: parentDirectory)
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
                    load(directory:filePath)
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
