// Keeps the spoken answer out of the user's dictation. Two modes:
//   mic-watch --wait-quiet   returns once the microphone has been off for a moment (exit 0), or gives up (exit 1)
//   mic-watch <pid of say>   stops that `say` the moment the microphone turns on; exits when the process ends
import CoreAudio
import Foundation

func property<T>(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector, _ initial: T) -> T? {
    var value = initial
    var size = UInt32(MemoryLayout<T>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    let status = AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value)
    return status == noErr ? value : nil
}

/// Whether any app is recording from the current default input device right now.
func microphoneIsOn() -> Bool {
    guard let input = property(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultInputDevice, AudioDeviceID(0)),
          let running = property(input, kAudioDevicePropertyDeviceIsRunningSomewhere, UInt32(0)) else { return false }
    return running != 0
}

let tick: useconds_t = 150_000

if CommandLine.arguments.count == 2, CommandLine.arguments[1] == "--wait-quiet" {
    // The user is dictating while the answer is ready: speaking now would land in their recording. Wait until the
    // microphone has been off for 2 s — a pause between two dictated phrases is shorter than that — and give up
    // after 10 minutes, so a call or a recorder left running does not keep an answer waiting forever.
    let quietNeeded = 2.0
    let giveUpAt = Date().addingTimeInterval(600)
    var quietSince: Date? = microphoneIsOn() ? nil : Date().addingTimeInterval(-quietNeeded)
    while Date() < giveUpAt {
        if microphoneIsOn() {
            quietSince = nil
        } else {
            let since = quietSince ?? Date()
            quietSince = since
            if Date().timeIntervalSince(since) >= quietNeeded { exit(0) }
        }
        usleep(tick)
    }
    exit(1)
}

guard CommandLine.arguments.count == 2, let speechPid = pid_t(CommandLine.arguments[1]) else { exit(2) }

// Only a microphone that turns ON while the answer is playing counts: the speech starts only once it is off, so
// an "on" seen here is the user starting to dictate again.
var wasOn = microphoneIsOn()
while kill(speechPid, 0) == 0 {
    let isOn = microphoneIsOn()
    if isOn && !wasOn {
        kill(speechPid, SIGTERM)
        break
    }
    wasOn = isOn
    usleep(tick)
}
