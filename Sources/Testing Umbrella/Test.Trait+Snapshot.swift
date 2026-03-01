// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-testing open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-testing project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

/// Adds snapshot-related trait factory methods.

// MARK: - Snapshot Trait

extension Test.Trait {
    /// The trait key for snapshot recording mode.
    private static let snapshotRecordingKey = "snapshot.recording"

    /// Creates a snapshot recording mode trait.
    ///
    /// Use this trait to control how snapshots are recorded for a test.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @Test(.snapshot(.record))
    /// func testNewFeature() {
    ///     #expectSnapshot(output, as: .lines)
    /// }
    ///
    /// @Test(.snapshot(.never))
    /// func testInCI() {
    ///     // Will fail if reference missing
    ///     #expectSnapshot(output, as: .lines)
    /// }
    /// ```
    ///
    /// ## Recording Modes
    ///
    /// - `.all`: Always record (overwrite existing)
    /// - `.missing`: Record if reference missing (default)
    /// - `.failed`: Record on failure + fail test
    /// - `.never`: Compare only; fail if missing (CI mode)
    ///
    /// - Parameter recording: The recording mode for snapshots in this test.
    /// - Returns: A trait that sets the snapshot recording mode.
    public static func snapshot(_ recording: Test.Snapshot.Recording) -> Self {
        .custom(snapshotRecordingKey, value: recording.rawValue)
    }

    /// Extracts the snapshot recording mode from a trait, if present.
    ///
    /// - Returns: The recording mode if this is a snapshot trait, nil otherwise.
    public var snapshotRecording: Test.Snapshot.Recording? {
        guard case .custom(let name, let value) = kind,
              name == Self.snapshotRecordingKey,
              let rawValue = value else {
            return nil
        }
        return Test.Snapshot.Recording(rawValue: rawValue)
    }
}

// MARK: - Traits Collection Extension

extension Swift.Collection where Element == Test.Trait {
    /// Finds the snapshot recording mode from a collection of traits.
    ///
    /// Returns the first snapshot recording trait found, or nil if none.
    ///
    /// - Returns: The snapshot recording mode from the traits.
    public var snapshotRecording: Test.Snapshot.Recording? {
        for trait in self {
            if let recording = trait.snapshotRecording {
                return recording
            }
        }
        return nil
    }
}
