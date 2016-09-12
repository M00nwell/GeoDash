//
//  GameScene.swift
//  GeoDash
//
//  Created by Wenzhe on 3/9/16.
//  Copyright (c) 2016 Wenzhe. All rights reserved.
//

import SpriteKit

var gameOption = Int()

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var refTimer = NSTimer()
    
    var person = SKSpriteNode()
    
    var isJumping = false
    var isTouching = false
    
    var ObsArray = [String]()
    
    var score = Int()
    var highScore = Int()
    var scoreTimer = NSTimer()
    var scoreLable = SKLabelNode()
    var highScoreLable = SKLabelNode()
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        scoreLable = childNodeWithName("scoreLable") as! SKLabelNode
        highScoreLable = childNodeWithName("highScoreLable") as! SKLabelNode
        score = 0
        let def = NSUserDefaults.standardUserDefaults()
        if def.integerForKey("highScore") != 0{
            highScore = def.integerForKey("highScore")
        }else{
            highScore = 0
        }
        updateLable()
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0, -30)
        person = scene?.childNodeWithName("person") as! SKSpriteNode
        switch gameOption {
        case 1:
            person.color = SKColor.greenColor()
            break
        case 2:
            person.color = SKColor.blueColor()
            break
        case 3:
            person.color = SKColor.blackColor()
            break
        default:
            person.color = SKColor.blackColor()
            break
        }
        
        refTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(GameScene.pickRef), userInfo: nil, repeats: true)
        scoreTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(GameScene.addScore), userInfo: nil, repeats: true)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        isTouching = true
        
        for touch in touches {
            let location = touch.locationInNode(self)
            let node = nodeAtPoint(location)
            
            if node.name == "retryBtn"{
                restartScene()
            }
            
        }
        
        jump()
       
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = false
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let a = contact.bodyA.node
        let b = contact.bodyB.node
        
        let result = (a?.physicsBody?.categoryBitMask)! | (b?.physicsBody?.categoryBitMask)!
        
        if result == 3 || result == 6{
            if self.physicsWorld.bodyAtPoint(CGPoint(x: person.position.x - 49, y: person.position.y - 51)) == nil &&
            self.physicsWorld.bodyAtPoint(CGPoint(x: person.position.x + 49, y: person.position.y - 51)) == nil {
                // No body directly under the person, cannot jump
                print("test")
                return
            }
            isJumping = false
            jump()
        }else if result == 10{
            for node in self.children{
                node.removeAllActions()
            }
            refTimer.invalidate()
            buildExplosion(person)
        }
    }
    
    func jump(){
        if isTouching {
            
            if isJumping == false {
                isJumping = true
                person.physicsBody?.applyImpulse(CGVectorMake(0,700))
            }
        }
    }
    
    func pickRef(){
        
        ObsArray = ["Obstacle1","Obstacle2","Obstacle3"]
        
        let randomNumber = arc4random() % UInt32(ObsArray.count)
        
        addRef(ObsArray[Int(randomNumber)])
        
    }
    
    func addRef(obsName: String){
        
        let ref = NSBundle.mainBundle().pathForResource(obsName, ofType: "sks")
        
        let refNode = SKReferenceNode(URL: NSURL(fileURLWithPath: ref!))
        
        refNode.position = CGPoint(x: (scene?.frame.size.width)!, y: 100)
        self.addChild(refNode)
        
        let moveAction = SKAction.moveToX(-refNode.scene!.frame.width, duration: 8)
        let removeAction = SKAction.removeFromParent()
        refNode.runAction(SKAction.sequence([moveAction,removeAction]))
        
    }
    
    func buildExplosion(sprite : SKSpriteNode){
        
        let explosion = SKEmitterNode(fileNamed: "Explosion.sks")
        explosion?.numParticlesToEmit = 500
        explosion?.runAction(SKAction.playSoundFileNamed("Explosion.wav", waitForCompletion: false))
        explosion?.position = sprite.position
        sprite.removeFromParent()
        addChild(explosion!)
        
        die()
        
    }
    
    func die(){
        
        scoreTimer.invalidate()
        let retryButton = SKSpriteNode(imageNamed: "retry")
        retryButton.name = "retryBtn"
        
        let wait = SKAction.waitForDuration(1.0)
        let fadeIn = SKAction.fadeInWithDuration(0.3)
        
        retryButton.alpha = 0
        retryButton.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        
        self.addChild(retryButton)
        retryButton.runAction(SKAction.sequence([wait, fadeIn]))
    }
    
    func restartScene(){
        let scene = GameScene(fileNamed: "GameScene")
        let transition = SKTransition.crossFadeWithDuration(0.5)
        let view = self.view as SKView!
        scene?.scaleMode = SKSceneScaleMode.AspectFill
        view.presentScene(scene!, transition: transition)
        score = 0
        updateLable()
    }
    
    func addScore(){
        score += 1
        
        if score > highScore {
            highScore = score
            let def = NSUserDefaults.standardUserDefaults()
            def.setInteger(highScore, forKey: "highScore")
        }
        updateLable()
    }
    
    func updateLable(){
        scoreLable.text = "\(score)"
        highScoreLable.text = "Highscore: \(highScore)"
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if person.position.x <= 0 - person.frame.width / 2 {
            for node in self.children{
                if node.name != "retryBtn"{
                    node.removeAllActions()
                }
            }
            refTimer.invalidate()
            die()
        }
    }
}
