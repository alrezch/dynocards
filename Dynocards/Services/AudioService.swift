//
//  AudioService.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import AVFoundation

class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()
    private var synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func playAudio(from url: String) {
        guard let audioURL = URL(string: url) else { return }
        
        URLSession.shared.dataTask(with: audioURL) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.play()
                } catch {
                    print("Audio playback error: \(error)")
                }
            }
        }.resume()
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func getLanguageCode(for language: String) -> String {
        switch language.lowercased() {
        case "english": return "en-US"
        case "spanish": return "es-ES"
        case "french": return "fr-FR"
        case "german": return "de-DE"
        case "italian": return "it-IT"
        case "portuguese": return "pt-PT"
        case "chinese": return "zh-CN"
        case "japanese": return "ja-JP"
        case "korean": return "ko-KR"
        case "arabic": return "ar-SA"
        default: return "en-US"
        }
    }
}

extension AudioService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Handle completion if needed
    }
} 