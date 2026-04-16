import AVFoundation
import UserNotifications
import UIKit

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]
    private init() { preload() }

    private func preload() {
        for name in ["message_in", "message_out", "notification", "splash"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "caf"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[name] = player
        }
    }

    private func play(_ name: String) {
        guard SettingsStore.shared.soundEnabled else { return }
        players[name]?.stop()
        players[name]?.currentTime = 0
        players[name]?.play()
    }

    func playMessageIn()  { play("message_in") }
    func playMessageOut() { play("message_out") }
    func playNotification() { play("notification") }

    func playSplash() {
        guard SettingsStore.shared.splashSoundEnabled else { return }
        play("splash")
    }

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendLocalNotification(title: String, body: String) {
        guard UIApplication.shared.applicationState != .active else { return }
        guard SettingsStore.shared.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = SettingsStore.shared.soundEnabled ? .default : nil

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
