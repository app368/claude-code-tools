import AVFoundation
import CoreMedia

// AppReview: prepares a recorded clip for upload to App Store Connect.
//
// Two jobs:
//   check  — inspect a clip and report what would stop Connect from accepting it
//   fit    — convert to the required frame size, lay in silence, trim the tail
//
// Usage:
//   ./fit check clip.mov
//   ./fit fit recording.mov out.mov 1920 1080 [seconds to keep]
//
// Why stretch. App Store accepts previews only at exact pixel dimensions, and a
// hand-drawn screen selection is never exact: a recording comes out at something
// like 2552×1432. The distortion from stretching is a fraction of a percent and
// invisible.
//
// Why silence. A screen recording made without a microphone carries no audio track
// at all, and Connect answers "unsupported or corrupted audio".

let args = CommandLine.arguments

func usage() -> Never {
    print("""
    AppReview — preview preparation for App Store

      ./fit check <clip>
      ./fit fit <recording> <output> <width> <height> [seconds]

    Example for Mac:
      ./fit fit record.mov preview.mov 1920 1080
    """)
    exit(1)
}

guard args.count > 2 else { usage() }
let command = args[1]

// MARK: - What the file is

struct Facts {
    var width = 0
    var height = 0
    var seconds = 0.0
    var hasAudio = false
    var audioRate = 0.0
    var audioChannels = 0
}

func read(_ url: URL) async -> Facts? {
    let asset = AVURLAsset(url: url)
    var facts = Facts()

    guard let track = try? await asset.loadTracks(withMediaType: .video).first,
          let natural = try? await track.load(.naturalSize),
          let transform = try? await track.load(.preferredTransform),
          let duration = try? await asset.load(.duration) else { return nil }

    let shown = natural.applying(transform)
    facts.width = Int(abs(shown.width))
    facts.height = Int(abs(shown.height))
    facts.seconds = duration.seconds

    if let audio = try? await asset.loadTracks(withMediaType: .audio), let first = audio.first {
        facts.hasAudio = true
        if let descs = try? await first.load(.formatDescriptions), !descs.isEmpty,
           let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(descs[0])?.pointee {
            facts.audioRate = asbd.mSampleRate
            facts.audioChannels = Int(asbd.mChannelsPerFrame)
        }
    }
    return facts
}

// MARK: - Check

/// Reports, in plain words, what would stop Connect from accepting the clip.
///
/// Apple's requirements: an exact frame size, a duration between fifteen and thirty
/// seconds, and an audio track that exists — silent is fine, missing is not.
func report(_ f: Facts, expected: CGSize?) {
    print("size       \(f.width)×\(f.height), aspect \(String(format: "%.3f", Double(f.width) / Double(f.height)))")
    print("duration   \(String(format: "%.1f", f.seconds)) s")
    if f.hasAudio {
        print("audio      present, \(Int(f.audioRate)) Hz, \(f.audioChannels) channels")
    } else {
        print("audio      NO TRACK")
    }
    print()

    var problems: [String] = []
    if !f.hasAudio {
        problems.append("no audio track — Connect will answer \"unsupported or corrupted audio\"")
    }
    if f.seconds < 15 {
        problems.append("shorter than fifteen seconds — will be refused")
    }
    if f.seconds > 30 {
        problems.append("longer than thirty seconds — trim the tail with the sixth argument to fit")
    }
    if let want = expected, Int(want.width) != f.width || Int(want.height) != f.height {
        problems.append("frame must be exactly \(Int(want.width))×\(Int(want.height))")
    }

    if problems.isEmpty {
        print("Ready to upload.")
    } else {
        print("What stands in the way:")
        for p in problems { print("  · \(p)") }
    }
}

// MARK: - Convert

func fit(source: URL, target: URL, size: CGSize, limit: Double) async {
    let asset = AVURLAsset(url: source)

    guard let sourceTrack = try? await asset.loadTracks(withMediaType: .video).first,
          let natural = try? await sourceTrack.load(.naturalSize),
          let transform = try? await sourceTrack.load(.preferredTransform),
          let duration = try? await asset.load(.duration) else {
        print("could not read the video track")
        return
    }

    let shown = natural.applying(transform)
    let width = abs(shown.width)
    let height = abs(shown.height)
    print("source \(Int(width))×\(Int(height)), \(String(format: "%.1f", duration.seconds)) s")

    var kept = duration
    if limit > 0, duration.seconds > limit {
        kept = CMTime(seconds: limit, preferredTimescale: duration.timescale)
        print("trimmed to \(String(format: "%.1f", limit)) s")
    }

    let composition = AVMutableComposition()
    let range = CMTimeRange(start: .zero, duration: kept)

    guard let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                       preferredTrackID: kCMPersistentTrackID_Invalid) else {
        print("could not create a video track")
        return
    }
    try? videoTrack.insertTimeRange(range, of: sourceTrack, at: .zero)

    // Silence goes in every time: only a microphone recording has audio of its own,
    // and a store page has no use for its content anyway
    if let silence = makeSilence(seconds: kept.seconds) {
        let silenceAsset = AVURLAsset(url: silence)
        if let track = try? await silenceAsset.loadTracks(withMediaType: .audio).first,
           let audioTrack = composition.addMutableTrack(withMediaType: .audio,
                                                        preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? audioTrack.insertTimeRange(range, of: track, at: .zero)
            print("silent track added")
        }
    }

    // Stretch each side independently to reach the exact frame
    let scale = CGAffineTransform(scaleX: size.width / width, y: size.height / height)
    let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    layer.setTransform(transform.concatenating(scale), at: .zero)

    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = range
    instruction.layerInstructions = [layer]

    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = size
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.instructions = [instruction]

    try? FileManager.default.removeItem(at: target)

    guard let export = AVAssetExportSession(asset: composition,
                                            presetName: AVAssetExportPresetHighestQuality) else {
        print("could not create the export session")
        return
    }
    export.outputURL = target
    export.outputFileType = .mov
    export.videoComposition = videoComposition

    await export.export()

    if export.status == .completed {
        print("done: \(target.path)")
        print()
        if let facts = await read(target) { report(facts, expected: size) }
    } else {
        print("failed: \(export.error?.localizedDescription ?? "unknown error")")
    }
}

/// Writes a file of silence of the given length: 44.1 kHz, two channels
func makeSilence(seconds: Double) -> URL? {
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("appreview-silence.caf")
    try? FileManager.default.removeItem(at: url)

    guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2),
          let file = try? AVAudioFile(forWriting: url, settings: format.settings),
          let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(44_100))
    else { return nil }

    buffer.frameLength = AVAudioFrameCount(44_100)  // zeroed buffer is the silence

    var written = 0.0
    while written < seconds {
        try? file.write(from: buffer)
        written += 1.0
    }
    return url
}

// MARK: - Command

let done = DispatchSemaphore(value: 0)

Task {
    switch command {
    case "check":
        let url = URL(fileURLWithPath: args[2])
        if let facts = await read(url) {
            print("— \((args[2] as NSString).lastPathComponent)")
            report(facts, expected: nil)
        } else {
            print("could not read the file")
        }

    case "fit":
        guard args.count > 5 else { usage() }
        let size = CGSize(width: Double(args[4]) ?? 1920, height: Double(args[5]) ?? 1080)
        let limit = args.count > 6 ? (Double(args[6]) ?? 0) : 0
        await fit(source: URL(fileURLWithPath: args[2]),
                  target: URL(fileURLWithPath: args[3]),
                  size: size,
                  limit: limit)

    default:
        usage()
    }
    done.signal()
}

done.wait()
