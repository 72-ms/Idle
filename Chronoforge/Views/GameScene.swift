import SpriteKit

class GameScene: SKScene {
    private var currentEra: Era = .ancient
    private var ambientEmitter: SKEmitterNode?
    private var tapCount: Int = 0

    var era: Era {
        get { currentEra }
        set {
            guard newValue != currentEra else { return }
            currentEra = newValue
            updateTheme()
        }
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        updateTheme()
    }

    // MARK: - Theme

    private func updateTheme() {
        ambientEmitter?.removeFromParent()
        children.filter { $0.name == "bg_element" }.forEach { $0.removeFromParent() }

        setupAmbientParticles()
        setupBackgroundElements()
    }

    private var eraColors: (primary: UIColor, secondary: UIColor, glow: UIColor) {
        switch currentEra {
        case .ancient:
            return (
                UIColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1),
                UIColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 1),
                UIColor(red: 0.7, green: 0.55, blue: 0.25, alpha: 0.3)
            )
        case .medieval:
            return (
                UIColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 1),
                UIColor(red: 0.6, green: 0.65, blue: 1.0, alpha: 1),
                UIColor(red: 0.3, green: 0.35, blue: 0.7, alpha: 0.3)
            )
        case .industrial:
            return (
                UIColor(red: 0.85, green: 0.65, blue: 0.3, alpha: 1),
                UIColor(red: 0.95, green: 0.75, blue: 0.4, alpha: 1),
                UIColor(red: 0.65, green: 0.5, blue: 0.2, alpha: 0.3)
            )
        case .digital:
            return (
                UIColor(red: 0.2, green: 0.9, blue: 0.9, alpha: 1),
                UIColor(red: 0.3, green: 1.0, blue: 1.0, alpha: 1),
                UIColor(red: 0.1, green: 0.6, blue: 0.7, alpha: 0.3)
            )
        case .cosmic:
            return (
                UIColor(red: 0.7, green: 0.4, blue: 0.9, alpha: 1),
                UIColor(red: 0.85, green: 0.55, blue: 1.0, alpha: 1),
                UIColor(red: 0.5, green: 0.25, blue: 0.7, alpha: 0.3)
            )
        }
    }

    // MARK: - Ambient Particles

    private func setupAmbientParticles() {
        let colors = eraColors
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = ambientParticleRate
        emitter.particleLifetime = 5
        emitter.particleLifetimeRange = 2
        emitter.particleSpeed = ambientParticleSpeed
        emitter.particleSpeedRange = 5
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.4
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.08
        emitter.particleScale = 0.04
        emitter.particleScaleRange = 0.03
        emitter.particleScaleSpeed = -0.005
        emitter.particleColor = colors.primary
        emitter.particleColorBlendFactor = 1
        emitter.particleTexture = circleTexture(size: 10)
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        emitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: size.height * 0.6)

        addChild(emitter)
        ambientEmitter = emitter
    }

    private var ambientParticleRate: CGFloat {
        switch currentEra {
        case .ancient: return 4
        case .medieval: return 3
        case .industrial: return 6
        case .digital: return 8
        case .cosmic: return 10
        }
    }

    private var ambientParticleSpeed: CGFloat {
        switch currentEra {
        case .ancient: return 8
        case .medieval: return 6
        case .industrial: return 12
        case .digital: return 15
        case .cosmic: return 5
        }
    }

    // MARK: - Background Elements

    private func setupBackgroundElements() {
        switch currentEra {
        case .ancient:
            addSunRays()
        case .medieval:
            addCandleFlickers()
        case .industrial:
            addSteamWisps()
        case .digital:
            addDataStreams()
        case .cosmic:
            addStarfield()
        }
    }

    private func addSunRays() {
        for i in 0..<6 {
            let ray = SKShapeNode(rectOf: CGSize(width: 1.5, height: size.height * 0.4))
            ray.fillColor = eraColors.glow
            ray.strokeColor = .clear
            ray.alpha = 0.15
            ray.position = CGPoint(x: size.width / 2, y: size.height / 2)
            ray.zRotation = CGFloat(i) * (.pi / 3)
            ray.name = "bg_element"

            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 60)
            ray.run(.repeatForever(rotate))
            addChild(ray)
        }
    }

    private func addCandleFlickers() {
        for _ in 0..<5 {
            let x = CGFloat.random(in: 20...(size.width - 20))
            let y = CGFloat.random(in: 20...(size.height - 20))

            let glow = SKShapeNode(circleOfRadius: CGFloat.random(in: 8...15))
            glow.fillColor = UIColor(red: 1, green: 0.8, blue: 0.3, alpha: 0.08)
            glow.strokeColor = .clear
            glow.position = CGPoint(x: x, y: y)
            glow.name = "bg_element"

            let pulse = SKAction.sequence([
                .fadeAlpha(to: 0.12, duration: Double.random(in: 1...2)),
                .fadeAlpha(to: 0.04, duration: Double.random(in: 1...2)),
            ])
            glow.run(.repeatForever(pulse))
            addChild(glow)
        }
    }

    private func addSteamWisps() {
        let spawn = SKAction.run { [weak self] in
            guard let self = self else { return }
            let wisp = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
            wisp.fillColor = UIColor.white.withAlphaComponent(0.1)
            wisp.strokeColor = .clear
            wisp.position = CGPoint(
                x: CGFloat.random(in: 0...self.size.width),
                y: 0
            )
            wisp.name = "bg_element"
            self.addChild(wisp)

            let rise = SKAction.moveBy(x: CGFloat.random(in: -30...30),
                                        y: self.size.height + 20, duration: Double.random(in: 4...7))
            let fade = SKAction.fadeOut(withDuration: 3)
            let scale = SKAction.scale(to: 2.0, duration: 5)
            let group = SKAction.group([rise, fade, scale])
            wisp.run(.sequence([group, .removeFromParent()]))
        }

        let delay = SKAction.wait(forDuration: 0.8, withRange: 0.5)
        run(.repeatForever(.sequence([spawn, delay])))
    }

    private func addDataStreams() {
        let spawn = SKAction.run { [weak self] in
            guard let self = self else { return }
            let x = CGFloat.random(in: 0...self.size.width)

            for j in 0..<3 {
                let dot = SKShapeNode(circleOfRadius: 1.5)
                dot.fillColor = self.eraColors.primary.withAlphaComponent(0.4)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: x, y: self.size.height + CGFloat(j * 8))
                dot.name = "bg_element"
                self.addChild(dot)

                let fall = SKAction.moveBy(x: 0, y: -(self.size.height + 30),
                                            duration: Double.random(in: 1.5...3))
                dot.run(.sequence([fall, .removeFromParent()]))
            }
        }

        let delay = SKAction.wait(forDuration: 0.3, withRange: 0.2)
        run(.repeatForever(.sequence([spawn, delay])))
    }

    private func addStarfield() {
        for _ in 0..<30 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.1...0.5)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.name = "bg_element"

            let twinkle = SKAction.sequence([
                .fadeAlpha(to: CGFloat.random(in: 0.5...0.8), duration: Double.random(in: 1...3)),
                .fadeAlpha(to: CGFloat.random(in: 0.05...0.2), duration: Double.random(in: 1...3)),
            ])
            star.run(.repeatForever(twinkle))
            addChild(star)
        }

        // Nebula glow
        let nebula = SKShapeNode(circleOfRadius: 40)
        nebula.fillColor = eraColors.glow
        nebula.strokeColor = .clear
        nebula.alpha = 0.15
        nebula.position = CGPoint(x: size.width * 0.3, y: size.height * 0.6)
        nebula.name = "bg_element"
        nebula.setScale(1.5)

        let pulse = SKAction.sequence([
            .scale(to: 1.8, duration: 4),
            .scale(to: 1.3, duration: 4),
        ])
        nebula.run(.repeatForever(pulse))
        addChild(nebula)
    }

    // MARK: - Tap Effects

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        spawnTapEffect(at: location)
        tapCount += 1
    }

    private func spawnTapEffect(at position: CGPoint) {
        let colors = eraColors
        let particleCount = min(12, 6 + tapCount / 100) // More particles as you play

        // Burst particles
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
            particle.fillColor = [colors.primary, colors.secondary].randomElement()!
            particle.strokeColor = .clear
            particle.position = position
            particle.alpha = 0.9
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...100)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: Double.random(in: 0.3...0.5))
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let scale = SKAction.scale(to: 0.1, duration: 0.4)
            let group = SKAction.group([move, fade, scale])
            particle.run(.sequence([group, .removeFromParent()]))
        }

        // Central flash
        let flash = SKShapeNode(circleOfRadius: 15)
        flash.fillColor = colors.secondary.withAlphaComponent(0.4)
        flash.strokeColor = .clear
        flash.position = position
        addChild(flash)

        let expand = SKAction.scale(to: 3.0, duration: 0.15)
        let fadeFlash = SKAction.fadeOut(withDuration: 0.15)
        flash.run(.sequence([.group([expand, fadeFlash]), .removeFromParent()]))

        // Ring wave
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.fillColor = .clear
        ring.strokeColor = colors.primary.withAlphaComponent(0.5)
        ring.lineWidth = 2
        ring.position = position
        addChild(ring)

        let expandRing = SKAction.scale(to: 4.0, duration: 0.3)
        expandRing.timingMode = .easeOut
        let fadeRing = SKAction.fadeOut(withDuration: 0.3)
        ring.run(.sequence([.group([expandRing, fadeRing]), .removeFromParent()]))

        // Rising text
        let label = SKLabelNode(text: "+1")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 20
        label.fontColor = colors.primary
        label.position = CGPoint(x: position.x + CGFloat.random(in: -10...10),
                                  y: position.y + 15)
        addChild(label)

        let rise = SKAction.moveBy(x: 0, y: 50, duration: 0.7)
        rise.timingMode = .easeOut
        let fadeTxt = SKAction.fadeOut(withDuration: 0.5)
        fadeTxt.timingMode = .easeIn
        let scaleTxt = SKAction.scale(to: 0.6, duration: 0.7)
        label.run(.sequence([
            .wait(forDuration: 0.1),
            .group([rise, fadeTxt, scaleTxt]),
            .removeFromParent()
        ]))
    }

    // MARK: - Milestone Effect

    func playMilestoneEffect() {
        let colors = eraColors
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Big ring burst
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: 10)
            ring.fillColor = .clear
            ring.strokeColor = colors.secondary.withAlphaComponent(0.6)
            ring.lineWidth = 3
            ring.position = center
            addChild(ring)

            let delay = Double(i) * 0.1
            let expand = SKAction.scale(to: 15.0, duration: 0.8)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.8)
            ring.run(.sequence([
                .wait(forDuration: delay),
                .group([expand, fade]),
                .removeFromParent()
            ]))
        }

        // Particle explosion
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
            particle.fillColor = [colors.primary, colors.secondary, .white].randomElement()!
            particle.strokeColor = .clear
            particle.position = center
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...200)
            let move = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.6)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.8)
            particle.run(.sequence([.group([move, fade]), .removeFromParent()]))
        }
    }

    // MARK: - Helpers

    private func circleTexture(size: CGFloat) -> SKTexture {
        let s = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: s)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: s))
        }
        return SKTexture(image: image)
    }
}
