import Testing
import Testing_Test_Support
import Test_Primitives

extension Test_Primitives.Test.Trait {
    @Suite
    struct SnapshotTest {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Trait.SnapshotTest.Unit {
    @Testing.Test
    func `snapshot trait with each Recording mode creates correct trait`() {
        for mode in Test_Primitives.Test.Snapshot.Recording.allCases {
            let trait = Test_Primitives.Test.Trait.snapshot(mode)
            #expect(trait.snapshotRecording == mode)
        }
    }

    @Testing.Test
    func `snapshotRecording extracts recording mode from snapshot trait`() {
        let trait = Test_Primitives.Test.Trait.snapshot(.all)
        #expect(trait.snapshotRecording == .all)
    }

    @Testing.Test
    func `Collection snapshotRecording finds first snapshot trait`() {
        let traits: [Test_Primitives.Test.Trait] = [
            .enabled(true),
            .snapshot(.never),
            .snapshot(.all),
        ]
        #expect(traits.snapshotRecording == .never)
    }
}

// MARK: - EdgeCase

extension Test_Primitives.Test.Trait.SnapshotTest.EdgeCase {
    @Testing.Test
    func `snapshotRecording returns nil for non-snapshot trait`() {
        let trait = Test_Primitives.Test.Trait.enabled(true)
        #expect(trait.snapshotRecording == nil)
    }

    @Testing.Test
    func `Collection snapshotRecording returns nil for empty array`() {
        let traits: [Test_Primitives.Test.Trait] = []
        #expect(traits.snapshotRecording == nil)
    }
}
