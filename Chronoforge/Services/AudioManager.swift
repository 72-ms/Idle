import AVFoundation
import UIKit

class AudioManager {
    static let shared = AudioManager()

    private var audioEngine: AVAudioEngine?
    private var playerNodes: [String: AVAudioPlayerNode] = [:]
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var musicPlayer: AVAudioPlayerNode?
    private var musicBuffer: AVAudioPCMBuffer?
    private var isMusicPlaying = false

    var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    var musicEnabled: Bool {
        UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true
    }

    init() {
        setupAudioSession()
        setupEngine()
        synthesizeAllSounds()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Session setup failed: \(error)")
        }
    }

    private func setupEngine() {
        audioEngine = AVAudioEngine()
    }

    // MARK: - Sound Synthesis

    private func synthesizeAllSounds() {
        let sampleRate: Double = 44100

        // Tap sound — short bright click
        buffers["tap"] = synthesizeTap(sampleRate: sampleRate)

        // Purchase sound — satisfying "cha-ching" ding
        buffers["purchase"] = synthesizePurchase(sampleRate: sampleRate)

        // Upgrade sound — ascending tone
        buffers["upgrade"] = synthesizeUpgrade(sampleRate: sampleRate)

        // Prestige sound — epic chime
        buffers["prestige"] = synthesizePrestige(sampleRate: sampleRate)

        // Epoch sound — deep resonant gong
        buffers["epoch"] = synthesizeEpoch(sampleRate: sampleRate)

        // Milestone sound — triumphant fanfare note
        buffers["milestone"] = synthesizeMilestone(sampleRate: sampleRate)

        // Error/denied sound — short low buzz
        buffers["denied"] = synthesizeDenied(sampleRate: sampleRate)

        // Relic forge sound — metallic shimmer
        buffers["forge"] = synthesizeForge(sampleRate: sampleRate)

        // Daily reward sound — cheerful jingle
        buffers["reward"] = synthesizeReward(sampleRate: sampleRate)

        // Material drop sound — soft clink
        buffers["material"] = synthesizeMaterial(sampleRate: sampleRate)

        // Achievement sound — triumphant chord
        buffers["achievement"] = synthesizeAchievement(sampleRate: sampleRate)

        // UI navigate sound — subtle click
        buffers["navigate"] = synthesizeNavigate(sampleRate: sampleRate)

        // Music buffers per era
        buffers["music_ancient"] = synthesizeAmbientMusic(era: .ancient, sampleRate: sampleRate)
        buffers["music_medieval"] = synthesizeAmbientMusic(era: .medieval, sampleRate: sampleRate)
        buffers["music_industrial"] = synthesizeAmbientMusic(era: .industrial, sampleRate: sampleRate)
        buffers["music_digital"] = synthesizeAmbientMusic(era: .digital, sampleRate: sampleRate)
        buffers["music_cosmic"] = synthesizeAmbientMusic(era: .cosmic, sampleRate: sampleRate)
    }

    // MARK: - Playback

    func play(_ sound: GameSound) {
        guard soundEnabled else { return }
        guard let buffer = buffers[sound.rawValue] else { return }

        guard let engine = audioEngine else { return }

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: buffer.format)

        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }

        playerNode.scheduleBuffer(buffer) { [weak engine] in
            DispatchQueue.main.async {
                engine?.detach(playerNode)
            }
        }
        playerNode.volume = sound.volume
        playerNode.play()
    }

    func playMusic(for era: Era) {
        guard musicEnabled else { return }
        let key = "music_\(era.rawValue)"
        guard let buffer = buffers[key] else { return }
        guard let engine = audioEngine else { return }

        stopMusic()

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: buffer.format)

        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }

        // Loop the music
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = 0.15
        player.play()

        musicPlayer = player
        isMusicPlaying = true
    }

    func stopMusic() {
        musicPlayer?.stop()
        if let player = musicPlayer, let engine = audioEngine {
            engine.detach(player)
        }
        musicPlayer = nil
        isMusicPlaying = false
    }

    func stopAll() {
        stopMusic()
        audioEngine?.stop()
    }

    // MARK: - Sound Synthesis Implementations

    private func synthesizeTap(sampleRate: Double) -> AVAudioPCMBuffer {
        // Short bright click: high frequency sine burst with fast decay
        let duration: Double = 0.06
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 60)
            let signal = sin(2 * .pi * 2400 * t) * 0.3 + sin(2 * .pi * 3600 * t) * 0.15
            data[i] = Float(signal * envelope)
        }
        return buffer
    }

    private func synthesizePurchase(sampleRate: Double) -> AVAudioPCMBuffer {
        // Satisfying cha-ching: two-note ascending with shimmer
        let duration: Double = 0.25
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let note1Env = t < 0.1 ? exp(-t * 20) : 0
            let note2Env = t > 0.08 ? exp(-(t - 0.08) * 15) : 0
            let note1 = sin(2 * .pi * 1200 * t) * note1Env
            let note2 = sin(2 * .pi * 1800 * t) * note2Env
            let shimmer = sin(2 * .pi * 4800 * t) * exp(-t * 25) * 0.1
            data[i] = Float((note1 + note2) * 0.3 + shimmer)
        }
        return buffer
    }

    private func synthesizeUpgrade(sampleRate: Double) -> AVAudioPCMBuffer {
        // Ascending sweep with harmonic overlay
        let duration: Double = 0.3
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let freq = 600 + 1200 * (t / duration)
            let envelope = (1 - t / duration) * exp(-t * 5)
            let signal = sin(2 * .pi * freq * t) * 0.3 + sin(2 * .pi * freq * 1.5 * t) * 0.1
            data[i] = Float(signal * envelope)
        }
        return buffer
    }

    private func synthesizePrestige(sampleRate: Double) -> AVAudioPCMBuffer {
        // Epic chime: major chord with reverb-like decay
        let duration: Double = 1.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let frequencies: [(Double, Double, Double)] = [
            (523.25, 0.25, 3.0),   // C5
            (659.25, 0.20, 2.8),   // E5
            (783.99, 0.20, 2.5),   // G5
            (1046.50, 0.15, 4.0),  // C6 (octave)
            (1318.51, 0.10, 5.0),  // E6 (shimmer)
        ]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0
            for (freq, amp, decay) in frequencies {
                sample += sin(2 * .pi * freq * t) * amp * exp(-t * decay)
            }
            // Soft attack
            let attack = min(1.0, t * 20)
            data[i] = Float(sample * attack * 0.4)
        }
        return buffer
    }

    private func synthesizeEpoch(sampleRate: Double) -> AVAudioPCMBuffer {
        // Deep resonant gong: low frequency with rich harmonics
        let duration: Double = 2.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let harmonics: [(Double, Double, Double)] = [
            (110.0, 0.30, 1.5),    // A2 fundamental
            (220.0, 0.20, 2.0),    // A3
            (330.0, 0.15, 2.5),    // E4
            (440.0, 0.12, 3.0),    // A4
            (554.37, 0.08, 3.5),   // C#5
            (880.0, 0.05, 5.0),    // A5 shimmer
        ]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0
            for (freq, amp, decay) in harmonics {
                // Slight detuning for richness
                let detune = 1.0 + sin(t * 3) * 0.002
                sample += sin(2 * .pi * freq * detune * t) * amp * exp(-t * decay)
            }
            let attack = min(1.0, t * 50)
            data[i] = Float(sample * attack * 0.5)
        }
        return buffer
    }

    private func synthesizeMilestone(sampleRate: Double) -> AVAudioPCMBuffer {
        // Quick triumphant 3-note ascending
        let duration: Double = 0.4
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let notes: [(Double, Double, Double, Double)] = [
            (523.25, 0.0, 0.12, 15),   // C5
            (659.25, 0.10, 0.12, 15),  // E5
            (783.99, 0.20, 0.20, 8),   // G5 (longer)
        ]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0
            for (freq, start, dur, decay) in notes {
                let localT = t - start
                guard localT >= 0 && localT < dur else { continue }
                let env = exp(-localT * decay)
                sample += sin(2 * .pi * freq * t) * env * 0.25
                sample += sin(2 * .pi * freq * 2 * t) * env * 0.08
            }
            data[i] = Float(sample)
        }
        return buffer
    }

    private func synthesizeDenied(sampleRate: Double) -> AVAudioPCMBuffer {
        // Short low buzz
        let duration: Double = 0.12
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 25)
            let signal = sin(2 * .pi * 200 * t) * 0.3 + sin(2 * .pi * 150 * t) * 0.2
            data[i] = Float(signal * envelope)
        }
        return buffer
    }

    private func synthesizeForge(sampleRate: Double) -> AVAudioPCMBuffer {
        // Metallic shimmer: inharmonic partials with fast attack
        let duration: Double = 0.8
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let partials: [(Double, Double, Double)] = [
            (800, 0.20, 4),
            (1236, 0.18, 5),
            (1853, 0.12, 6),
            (2714, 0.08, 8),
            (3987, 0.05, 10),
        ]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0
            for (freq, amp, decay) in partials {
                sample += sin(2 * .pi * freq * t) * amp * exp(-t * decay)
            }
            // Hammer attack
            let attack = min(1.0, t * 100)
            // White noise burst for anvil strike
            let noise = t < 0.02 ? Double.random(in: -0.15...0.15) * (1 - t / 0.02) : 0
            data[i] = Float((sample * attack + noise) * 0.5)
        }
        return buffer
    }

    private func synthesizeReward(sampleRate: Double) -> AVAudioPCMBuffer {
        // Cheerful ascending arpeggio
        let duration: Double = 0.6
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let notes: [(Double, Double)] = [
            (523.25, 0.0),    // C5
            (659.25, 0.08),   // E5
            (783.99, 0.16),   // G5
            (1046.50, 0.24),  // C6
        ]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0
            for (freq, start) in notes {
                let localT = t - start
                guard localT >= 0 else { continue }
                let env = exp(-localT * 6)
                sample += sin(2 * .pi * freq * t) * env * 0.2
            }
            data[i] = Float(sample)
        }
        return buffer
    }

    private func synthesizeMaterial(sampleRate: Double) -> AVAudioPCMBuffer {
        // Soft metallic clink
        let duration: Double = 0.15
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env = exp(-t * 40)
            let signal = sin(2 * .pi * 3200 * t) * 0.15 + sin(2 * .pi * 4800 * t) * 0.1
            data[i] = Float(signal * env)
        }
        return buffer
    }

    private func synthesizeAchievement(sampleRate: Double) -> AVAudioPCMBuffer {
        // Triumphant major chord with fanfare feel
        let duration: Double = 1.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        // G major chord spread
        let notes: [(Double, Double, Double, Double)] = [
            (392.0, 0.0, 0.25, 4),     // G4
            (493.88, 0.05, 0.22, 4),   // B4
            (587.33, 0.10, 0.22, 3.5), // D5
            (783.99, 0.15, 0.20, 3),   // G5
            (987.77, 0.20, 0.15, 5),   // B5
        ]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0
            for (freq, start, amp, decay) in notes {
                let localT = t - start
                guard localT >= 0 else { continue }
                let env = exp(-localT * decay) * min(1.0, localT * 30)
                sample += sin(2 * .pi * freq * t) * amp * env
            }
            data[i] = Float(sample * 0.35)
        }
        return buffer
    }

    private func synthesizeNavigate(sampleRate: Double) -> AVAudioPCMBuffer {
        // Subtle UI click
        let duration: Double = 0.03
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env = exp(-t * 120)
            data[i] = Float(sin(2 * .pi * 1800 * t) * 0.15 * env)
        }
        return buffer
    }

    // MARK: - Ambient Music Synthesis

    private func synthesizeAmbientMusic(era: Era, sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 16.0 // 16-second loop
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let params = musicParams(for: era)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0

            // Pad drone — slow-evolving chord
            for (j, freq) in params.padFreqs.enumerated() {
                let phase = t * freq * 2 * .pi
                let lfo = 1.0 + sin(t * params.lfoSpeeds[j % params.lfoSpeeds.count]) * 0.003
                sample += sin(phase * lfo) * params.padAmplitude
            }

            // Slow arpeggio notes
            let arpeggioPos = t.truncatingRemainder(dividingBy: params.arpeggioLength)
            let noteIndex = Int(arpeggioPos / params.noteDuration) % params.arpeggioNotes.count
            let noteT = arpeggioPos.truncatingRemainder(dividingBy: params.noteDuration)
            let noteFreq = params.arpeggioNotes[noteIndex]
            let noteEnv = exp(-noteT * params.noteDecay) * min(1.0, noteT * 20)
            sample += sin(2 * .pi * noteFreq * t) * noteEnv * params.noteAmplitude

            // Subtle sub-bass movement
            let subFreq = params.subFreq + sin(t * 0.1) * 5
            sample += sin(2 * .pi * subFreq * t) * params.subAmplitude

            // Crossfade at loop boundary for seamless looping
            let fadeTime: Double = 0.5
            var gain: Double = 1.0
            if t < fadeTime {
                gain = t / fadeTime
            } else if t > duration - fadeTime {
                gain = (duration - t) / fadeTime
            }

            data[i] = Float(sample * gain * 0.12)
        }
        return buffer
    }

    private struct MusicParams {
        let padFreqs: [Double]
        let padAmplitude: Double
        let lfoSpeeds: [Double]
        let arpeggioNotes: [Double]
        let arpeggioLength: Double
        let noteDuration: Double
        let noteDecay: Double
        let noteAmplitude: Double
        let subFreq: Double
        let subAmplitude: Double
    }

    private func musicParams(for era: Era) -> MusicParams {
        switch era {
        case .ancient:
            // Warm, mystical — A minor pentatonic feel
            return MusicParams(
                padFreqs: [220, 329.63, 440],
                padAmplitude: 0.15,
                lfoSpeeds: [0.3, 0.5, 0.7],
                arpeggioNotes: [440, 523.25, 659.25, 587.33, 440, 392, 329.63, 392],
                arpeggioLength: 8.0, noteDuration: 1.0, noteDecay: 3.0, noteAmplitude: 0.2,
                subFreq: 110, subAmplitude: 0.08
            )
        case .medieval:
            // Dark, modal — D Dorian feel
            return MusicParams(
                padFreqs: [146.83, 220, 293.66],
                padAmplitude: 0.12,
                lfoSpeeds: [0.2, 0.4, 0.6],
                arpeggioNotes: [293.66, 349.23, 392, 440, 392, 349.23, 329.63, 293.66],
                arpeggioLength: 8.0, noteDuration: 1.0, noteDecay: 4.0, noteAmplitude: 0.18,
                subFreq: 73.42, subAmplitude: 0.1
            )
        case .industrial:
            // Rhythmic, mechanical — minor key with pulse
            return MusicParams(
                padFreqs: [164.81, 246.94, 329.63],
                padAmplitude: 0.10,
                lfoSpeeds: [0.8, 1.2, 0.4],
                arpeggioNotes: [329.63, 392, 329.63, 493.88, 392, 329.63, 293.66, 329.63],
                arpeggioLength: 4.0, noteDuration: 0.5, noteDecay: 6.0, noteAmplitude: 0.15,
                subFreq: 82.41, subAmplitude: 0.12
            )
        case .digital:
            // Electronic, crystalline — major 7th feel
            return MusicParams(
                padFreqs: [261.63, 392, 493.88],
                padAmplitude: 0.08,
                lfoSpeeds: [1.5, 2.0, 0.8],
                arpeggioNotes: [523.25, 659.25, 783.99, 987.77, 783.99, 659.25, 587.33, 523.25],
                arpeggioLength: 4.0, noteDuration: 0.5, noteDecay: 8.0, noteAmplitude: 0.12,
                subFreq: 130.81, subAmplitude: 0.06
            )
        case .cosmic:
            // Ethereal, vast — suspended/open feel
            return MusicParams(
                padFreqs: [130.81, 196, 293.66, 392],
                padAmplitude: 0.10,
                lfoSpeeds: [0.15, 0.25, 0.35, 0.45],
                arpeggioNotes: [392, 523.25, 587.33, 783.99, 1046.50, 783.99, 587.33, 523.25],
                arpeggioLength: 16.0, noteDuration: 2.0, noteDecay: 2.0, noteAmplitude: 0.15,
                subFreq: 65.41, subAmplitude: 0.1
            )
        }
    }
}

// MARK: - Sound Types

enum GameSound: String {
    case tap
    case purchase
    case upgrade
    case prestige
    case epoch
    case milestone
    case denied
    case forge
    case reward
    case material
    case achievement
    case navigate

    var volume: Float {
        switch self {
        case .tap: return 0.4
        case .purchase: return 0.6
        case .upgrade: return 0.5
        case .prestige: return 0.8
        case .epoch: return 0.9
        case .milestone: return 0.7
        case .denied: return 0.3
        case .forge: return 0.7
        case .reward: return 0.7
        case .material: return 0.2
        case .achievement: return 0.8
        case .navigate: return 0.2
        }
    }
}
