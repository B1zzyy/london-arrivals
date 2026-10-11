import Foundation
import AVFoundation

public final class AudioAnnouncer: NSObject, ObservableObject {
    public static let shared = AudioAnnouncer()

    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false

    private override init() {
        super.init()
    }

    public func announceArrival(prediction: ArrivalPrediction, platform: String? = nil) {
        let plat = platform ?? prediction.cleanPlatform
        let dest = prediction.cleanDestination
        let line = prediction.lineName
        let minutes = prediction.minutesUntilArrival

        var text = ""
        if minutes == 0 {
            text = "The next train on \(plat) is the \(line) service to \(dest). This train is now arriving."
        } else if minutes == 1 {
            text = "The next train on \(plat) is the \(line) service to \(dest), arriving in 1 minute."
        } else {
            text = "The next train on \(plat) is the \(line) service to \(dest), arriving in \(minutes) minutes."
        }

        speak(text: text)
    }

    public func announceBoard(station: String, predictions: [ArrivalPrediction]) {
        guard let first = predictions.first else {
            speak(text: "There are currently no trains scheduled from \(station).")
            return
        }
        announceArrival(prediction: first)
    }

    public func speak(text: String) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        // Prefer British English voice for authentic London transport announcements
        if let britishVoice = AVSpeechSynthesisVoice(language: "en-GB") {
            utterance.voice = britishVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en-GB")
        }
        utterance.rate = 0.48 // Measured, clear London station announcer cadence
        utterance.pitchMultiplier = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}
