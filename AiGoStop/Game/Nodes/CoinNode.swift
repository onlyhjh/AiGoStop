//
//  CoinNode.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 6/24/26.
//
import SpriteKit

class CoinNode: SKSpriteNode {
    
    init(position: CGPoint) {
        let texture = SKTexture(image: .coin)
        super.init(texture: texture, color: .clear, size: CGSize(width: 100, height: 100))
        
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func moveToWinner(movePosition: CGPoint, duration: TimeInterval = 0, completion: (() -> Void)? = nil) {
        self.zPosition = 1000
        var sequnce: [SKAction] = []
        
        let halfPosition = CGPoint(x: movePosition.x - ((movePosition.x - self.position.x) / 2), y: movePosition.y - ((movePosition.y - self.position.y) / 2))
        //print("\(#function) halfPosition: \(halfPosition) = movePosition: \(movePosition) - self.position: \(self.position)  ")
        let move1Action = SKAction.move(to: halfPosition, duration: duration / 2)
        let scaleUpAction = SKAction.scale(to: 3.0, duration: duration / 2)
        let moveWithScaleUpAction = SKAction.group([move1Action, scaleUpAction])
        
        let move2Action = SKAction.move(to: movePosition, duration: duration / 2)
        let scaleDownAction = SKAction.scale(to: 1.0, duration: duration / 2)
        let moveWithScaleDownAction = SKAction.group([move2Action, scaleDownAction])

        if UserDefaults.standard.effectSound {
            let fileName = "\(SoundType.coinClink.rawValue).mp3"
            let soundAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
            sequnce = [moveWithScaleUpAction, soundAction, moveWithScaleDownAction]
        }
        else {
            sequnce = [moveWithScaleUpAction, moveWithScaleDownAction]
        }
        
        run(SKAction.sequence(sequnce), completion: {
            self.removeFromParent()
            completion?()
        })
    }
}
