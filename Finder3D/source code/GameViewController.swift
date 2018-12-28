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
    let INITIAL_DISTANCE_FROM_CAMERA:Float = 50
    let INTERACTION_DISTANCE:Float = 10
    let MAX_MOVEMENT_SPEED:Float = 0.6
    let ROTATION_PER_FRAME_RADIANS:Float = 0.05
    
    //MARK: keyboard variables
    var upArrowPressed:Bool = false
    var downArrowPressed:Bool = false
    var leftArrowPressed:Bool = false
    var rightArrowPressed:Bool = false
    var spaceBarPressed:Bool = false
    var backSpacePressed:Bool = false
    
    //MARK: movement variables
    var currentMovementSpeed:Float = 0
    var rotation:Float = 0
    
    //MARK: scene object variables
    var camera:SCNNode! = nil
    var scene:SCNScene! = nil
    
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
                    
                self.resetCameraPosition()
                
                do {
                    var filesInNewDirectory = try FileManager.default.contentsOfDirectory(atPath: self.currentDirectoryPath)
                    filesInNewDirectory.sort()
                    self.fileIcons = self.createFileIconsFor(filenames: filesInNewDirectory)
                    self.addFileIconsToScene(fileIcons: self.fileIcons)
                }
                catch let error as NSError {
                    NSAlert.showWith(title: "Directory Load Error", message: "Ooops! Something went wrong while loading directory \(self.currentDirectoryPath): \(error)")
                }
                
                self.loadingScreen.hide()
                
            }
            
        })
        
    }
    
    func createFileIconsFor(filenames:[String]) -> [FileIcon]{
        
        var fileIcons:[FileIcon] = []
        for (i,filename) in filenames.enumerated(){
            
            let newFileIconPosition:(x:Float,y:Float,z:Float) = self.calculatePositionForFileIconAt(positionInLine: i, withTotalFilesToShow: filenames.count)
            let newFileIcon = FileIcon(fileName:filename, directoryPath:self.currentDirectoryPath, x:newFileIconPosition.x, y:newFileIconPosition.y, z:newFileIconPosition.z)
            fileIcons.append(newFileIcon)
            
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
        
        //when there are a number of files greater than or equal to MAX_ICONS_IN_ROW we arrange them in rows of length equal to MAX_ICONS_IN_ROW
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
        //when there are fewer than MAX_ICONS_IN_ROW files to show, we make one row and center it in front of the user
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
    
    func resetCameraPosition(){
        camera.simdPosition.x = 0
        camera.simdPosition.z = 0
        camera.eulerAngles.x = 0
        camera.eulerAngles.y = -0
        camera.eulerAngles.z = 0
    }
    
    func setupScene(){
        scene = SCNScene(named: "art.scnassets/main.scn")!
        if let scnView = self.view as? SCNView{
            scnView.scene = scene
            scnView.delegate = self
            scnView.loops = true
            scnView.isPlaying = true
        }
    }
    
    func goToParentDirectory(){
    
        //if the parent directory points to an actual directory
        let parentDirectory = (currentDirectoryPath as NSString).deletingLastPathComponent
        var isDirectory:ObjCBool = ObjCBool(false)
        if FileManager.default.fileExists(atPath: parentDirectory, isDirectory: &isDirectory) && isDirectory.boolValue == true{
            load(directory: parentDirectory)
        }else{
            NSAlert.showWith(title: "Could Not Load Parent Directory", message: "The parent directory ,\(parentDirectory), could not be loaded because it does not exist or is not a directory")
        }
            
    }
    
    //MARK: game loop
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval){
        
        processArrowKeyInput()
        
        updateCameraPosition()
        
        //un-highlighting all the icons
        for fileIcon in fileIcons{
            fileIcon.hideHighlight()
        }
        
        if let closestFileIcon = getClosestFileIcon(), getDistanceBetween(node1: camera, node2: closestFileIcon.node) < INTERACTION_DISTANCE{
                
            closestFileIcon.showHighlight()
            
            if spaceBarPressed {
                let filePath = currentDirectoryPath+"/"+closestFileIcon.name
                loadContentAt(path: filePath)
            }
            
        }
        
        if backSpacePressed {
            goToParentDirectory()
        }
        
        //resetting button pressed variables so that the button presses only take effect for a single frame per press
        resetButtonPresses()
        
    }
    
    func loadContentAt(path:String){
        var isDirectory:ObjCBool = ObjCBool(false)
        _ = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        if isDirectory.boolValue == true{
            load(directory:path)
        }else{
            NSWorkspace.shared.openFile(path)
        }
    }
    
    func resetButtonPresses(){
        spaceBarPressed = false
        backSpacePressed = false
    }
    
    func getClosestFileIcon() -> FileIcon?{
        var selectedFileIcon:FileIcon? = nil
        var selectedFileNodeDistance:Float = -1
        for fileIcon in fileIcons{
            let distance = getDistanceBetween(node1: camera, node2: fileIcon.node)
            if selectedFileIcon == nil || distance < selectedFileNodeDistance {
                selectedFileIcon = fileIcon
                selectedFileNodeDistance = distance
            }
        }
        return selectedFileIcon
    }
    
    func getDistanceBetween(node1:SCNNode, node2:SCNNode) -> Float{
        let deltaX = node1.simdPosition.x - node2.simdPosition.x
        let deltaZ = node1.simdPosition.z - node2.simdPosition.z
        return sqrt(deltaX*deltaX + deltaZ*deltaZ)
    }
    
    func processArrowKeyInput(){
        
        if leftArrowPressed{
            //rotating to the left
            camera.simdEulerAngles.y += ROTATION_PER_FRAME_RADIANS
        }
        if rightArrowPressed{
            //rotating to the right
            camera.simdEulerAngles.y -= ROTATION_PER_FRAME_RADIANS
        }
        
        if upArrowPressed && downArrowPressed{
            currentMovementSpeed = 0
        }else if upArrowPressed{
            //move forward
            currentMovementSpeed = -MAX_MOVEMENT_SPEED
        }else if downArrowPressed{
            //move backward
            currentMovementSpeed = MAX_MOVEMENT_SPEED
        }else{
            currentMovementSpeed = 0
        }
        
    }
    
    func updateCameraPosition(){
        
        camera.simdPosition.x += sin(camera.simdEulerAngles.y) * Float(currentMovementSpeed)
        camera.simdPosition.z += cos(camera.simdEulerAngles.y) * Float(currentMovementSpeed)
        
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
