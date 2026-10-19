// Stops a running `say` the moment the Mac's microphone starts recording, so the user can cut the answer off
// just by starting to dictate. Usage: mic-watch <pid of say>. Exits on its own when that process ends.
import CoreAudio
import Foundation

guard CommandLine.arguments.count == 2, let speechPid = pid_t(CommandLine.arguments[1]) else { exit(2) }

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

// Only a microphone that turns ON while the answer is playing counts: an app that already holds it open (a call,
// a recorder left running) must not silence every answer.
var wasOn = microphoneIsOn()
while kill(speechPid, 0) == 0 {
    let isOn = microphoneIsOn()
    if isOn && !wasOn {
        kill(speechPid, SIGTERM)
        break
    }
    wasOn = isOn
    usleep(150_000)
}
