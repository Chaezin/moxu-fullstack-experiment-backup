#!/usr/bin/swift

import AVFoundation
import Foundation

func fourCC(_ value: FourCharCode) -> String {
    let bytes: [UInt8] = [
        UInt8((value >> 24) & 0xff), UInt8((value >> 16) & 0xff),
        UInt8((value >> 8) & 0xff), UInt8(value & 0xff)
    ]
    return String(bytes: bytes, encoding: .ascii) ?? String(value)
}

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("Usage: video-probe <video> [video ...]\n".utf8))
    exit(2)
}

var results: [[String: Any]] = []

for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)
    let asset = AVURLAsset(url: url)
    var item: [String: Any] = ["path": path]

    do {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        item["file_size_bytes"] = attrs[.size] as? NSNumber ?? 0
    } catch {
        item["file_error"] = error.localizedDescription
    }

    let seconds = CMTimeGetSeconds(asset.duration)
    item["duration_seconds"] = seconds.isFinite ? seconds : NSNull()

    var streams: [[String: Any]] = []
    for track in asset.tracks {
        var stream: [String: Any] = [
            "media_type": track.mediaType.rawValue,
            "track_id": track.trackID,
            "enabled": track.isEnabled,
            "estimated_data_rate": track.estimatedDataRate
        ]

        if track.mediaType == .video {
            let transformed = track.naturalSize.applying(track.preferredTransform)
            stream["width"] = abs(transformed.width)
            stream["height"] = abs(transformed.height)
            stream["nominal_fps"] = track.nominalFrameRate
        }

        if let desc = track.formatDescriptions.first {
            stream["codec"] = fourCC(CMFormatDescriptionGetMediaSubType(desc as! CMFormatDescription))
        }
        streams.append(stream)
    }
    item["streams"] = streams
    results.append(item)
}

let output = try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
FileHandle.standardOutput.write(output)
FileHandle.standardOutput.write(Data("\n".utf8))
