//
//  Test.Trait+Snapshot.swift
//  swift-testing
//
//  Witness key for snapshot recording mode.
//

// MARK: - Witness Key

extension Test.Trait {
    /// Witness key for snapshot recording mode.
    public struct Snapshot: Sendable {
        /// The recording mode for snapshots.
        public let recording: Test.Snapshot.Recording

        /// Creates a snapshot value.
        public init(recording: Test.Snapshot.Recording) {
            self.recording = recording
        }
    }
}

extension Test.Trait.Snapshot: Witness.Key {
    public typealias Value = Test.Trait.Snapshot?

    @inlinable
    public static var liveValue: Test.Trait.Snapshot? { nil }
}

// MARK: - Collection Access

extension Test.Trait.Collection {
    /// The snapshot recording mode, if set.
    public var snapshotRecording: Test.Snapshot.Recording? {
        get { self[Test.Trait.Snapshot.self]?.recording }
        set {
            if let newValue {
                self[Test.Trait.Snapshot.self] = Test.Trait.Snapshot(recording: newValue)
            } else {
                self[Test.Trait.Snapshot.self] = nil
            }
        }
    }
}
