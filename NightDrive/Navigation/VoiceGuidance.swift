import AVFoundation
import Combine

struct VoiceCuePolicy {
    private var spoken = Set<String>()
    mutating func reset() { spoken.removeAll() }
    mutating func cue(routeID: UUID, maneuver: RouteManeuver, distance: Double) -> String? {
        let stage = distance <= 40 ? "now" : distance <= 300 ? "soon" : "far"
        guard stage != "far" else { return nil }
        let key = "\(routeID)-\(maneuver.id)-\(stage)"
        guard spoken.insert(key).inserted else { return nil }
        if stage == "now" {
            spoken.insert("\(routeID)-\(maneuver.id)-soon")
            return maneuver.instruction
        }
        return "In \(Int((distance / 10).rounded()) * 10) metres, \(maneuver.instruction.lowercased())"
    }
}

@MainActor
final class VoiceGuidance: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    @Published var isMuted = false { didSet { if isMuted { stop() } } }
    private let synthesizer = AVSpeechSynthesizer()
    private var policy = VoiceCuePolicy()
    private var observation: AnyCancellable?
    private var routeID: UUID?
    private let audioQueue = DispatchQueue(label: "NightDrive.voice-audio")
    private var audioEngaged = false
    private var activating = false
    private var audioGeneration = UUID()
    private var activeUtterance: AVSpeechUtterance?
    init(session: NavigationSession) {
        super.init()
        synthesizer.delegate = self
        synthesizer.usesApplicationAudioSession = true
        #if DEBUG
        isMuted = ProcessInfo.processInfo.arguments.contains("--mute-guidance")
        #endif
        observation = session.objectWillChange.receive(on: RunLoop.main).sink { [weak self, weak session] _ in
            guard let self, let session else { return }
            guard session.phase == .navigating, session.guidanceStatus == nil,
                  let route = session.route, let turn = session.nextManeuver else {
                self.stop()
                if session.route == nil { self.policy.reset(); self.routeID = nil }
                return
            }
            if self.routeID != route.id { self.policy.reset(); self.routeID = route.id }
            guard !self.isMuted, !self.activating, !self.synthesizer.isSpeaking,
                  let cue = self.policy.cue(routeID: route.id, maneuver: turn, distance: session.distanceToManeuver) else { return }
            self.speak(cue)
        }
    }
    private func speak(_ text: String) {
        let token = UUID(); audioGeneration = token
        activating = true; audioEngaged = true
        // iOS 26's activation API is synchronous. Keep it off the UI thread,
        // serialized with deactivation so cancellation cannot leave audio ducked.
        audioQueue.async { [weak self] in
            let audio = AVAudioSession.sharedInstance()
            var activated = false
            do {
                try audio.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
                try audio.setActive(true)
                activated = true
            } catch { }
            let ready = activated
            DispatchQueue.main.async {
                guard let self, self.audioGeneration == token else { return }
                self.activating = false
                guard ready, !self.isMuted else { self.releaseAudio(); return }
                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
                self.activeUtterance = utterance
                self.synthesizer.speak(utterance)
            }
        }
    }
    private func stop() {
        audioGeneration = UUID(); activating = false
        activeUtterance = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        releaseAudio()
    }
    private func releaseAudio() {
        guard audioEngaged else { return }
        audioEngaged = false
        audioQueue.async { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard activeUtterance === utterance else { return }; activeUtterance = nil; releaseAudio()
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard activeUtterance === utterance else { return }; activeUtterance = nil; releaseAudio()
    }
}
