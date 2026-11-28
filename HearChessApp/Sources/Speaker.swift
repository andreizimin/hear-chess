// Speech output. Design: docs/intent/voice/voice-design.md

import AVFoundation
import HearChessCore

// @spec VOICE-OUT-001, VOICE-OUT-002, VOICE-OUT-003, VOICE-OUT-004, VOICE-OUT-005
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?
    private var current: AVSpeechUtterance?
    var onFinished: (() -> Void)?

    override init() {
        voice = Speaker.bestEnglishVoice()
        super.init()
        synthesizer.delegate = self
        synthesizer.usesApplicationAudioSession = true
    }

    /// The highest-quality installed English voice, preferring the phone's own English region.
    static func bestEnglishVoice() -> AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        let region = Locale.current.region?.identifier ?? "US"
        func rank(_ v: AVSpeechSynthesisVoice) -> (Int, Int) {
            let quality: Int
            switch v.quality {
            case .premium: quality = 3
            case .enhanced: quality = 2
            default: quality = 1
            }
            return (quality, v.language.hasSuffix(region) ? 1 : 0)
        }
        return english.max { rank($0) < rank($1) } ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    func speak(_ text: String) {
        if synthesizer.isSpeaking { stop() }
        let utterance = AVSpeechUtterance(attributedString: Speaker.withLetterPronunciations(text))
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        current = utterance
        synthesizer.speak(utterance)
    }

    /// The phrase with each standalone file letter marked with its IPA name, so it is said as a letter.
    // @spec VOICE-OUT-005
    static func withLetterPronunciations(_ text: String) -> NSAttributedString {
        let marked = NSMutableAttributedString(string: text)
        for letter in SpokenChess.letterPronunciations(in: text) {
            marked.addAttribute(NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute),
                                value: letter.ipa, range: NSRange(letter.range, in: text))
        }
        return marked
    }

    func stop() {
        current = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard utterance === current else { return }
        current = nil
        onFinished?()
    }
}
