import SpriteKit

class GameScene: SKScene {
    private let particleColors: [UIColor] = [
        UIColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1),
        UIColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 1),
        UIColor(red: 0.8, green: 0.65, blue: 0.3, alpha: 1),
    ]

    override func didMove(to view: SKView) {
        backgroundColor = .clear

        // Ambient particles
        if let emitter = createAmbientParticles() {
            emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(emitter)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        spawnTapEffect(at: location)
    }

    private func spawnTapEffect(at position: CGPoint) {
        // Burst particles
        for _ in 0..<6 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = particleColors.randomElement() ?? .white
            particle.strokeColor = .clear
            particle.position = position
            particle.alpha = 0.9
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...80)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let scale = SKAction.scale(to: 0.1, duration: 0.4)
            let group = SKAction.group([move, fade, scale])
            let remove = SKAction.removeFromParent()
            particle.run(SKAction.sequence([group, remove]))
        }

        // Rising text
        let label = SKLabelNode(text: "+1")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = particleColors.first
        label.position = CGPoint(x: position.x, y: position.y + 10)
        label.alpha = 1
        addChild(label)

        let rise = SKAction.moveBy(x: 0, y: 40, duration: 0.6)
        let fade = SKAction.fadeOut(withDuration: 0.6)
        let group = SKAction.group([rise, fade])
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([group, remove]))
    }

    private func createAmbientParticles() -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 3
        emitter.particleLifetime = 4
        emitter.particleLifetimeRange = 2
        emitter.particleSpeed = 10
        emitter.particleSpeedRange = 5
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.3
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.1
        emitter.particleScale = 0.05
        emitter.particleScaleRange = 0.03
        emitter.particleColor = particleColors.first ?? .white
        emitter.particleColorBlendFactor = 1

        // Create a small circle texture
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        emitter.particleTexture = SKTexture(image: image)

        return emitter
    }
}
