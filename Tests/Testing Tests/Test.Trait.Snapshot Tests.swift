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
    func snapshotTraitWithEachRecordingModeCreatesCorrectTrait() {
        for mode in Test_Primitives.Test.Snapshot.Recording.allCases {
            let trait = Test_Primitives.Test.Trait.snapshot(mode)
            #expect(trait.snapshotRecording == mode)
        }
    }

    @Testing.Test
    func snapshotRecordingExtractsRecordingModeFromSnapshotTrait() {
        let trait = Test_Primitives.Test.Trait.snapshot(.all)
        #expect(trait.snapshotRecording == .all)
    }

    @Testing.Test
    func collectionSnapshotRecordingFindsFirstSnapshotTrait() {
        let traits: [Test_Primitives.Test.Trait] = [
            .enabled(if: true),
            .snapshot(.never),
            .snapshot(.all),
        ]
        #expect(traits.snapshotRecording == .never)
    }
}

// MARK: - EdgeCase

extension Test_Primitives.Test.Trait.SnapshotTest.EdgeCase {
    @Testing.Test
    func snapshotRecordingReturnsNilForNonSnapshotTrait() {
        let trait = Test_Primitives.Test.Trait.enabled(if: true)
        #expect(trait.snapshotRecording == nil)
    }

    @Testing.Test
    func collectionSnapshotRecordingReturnsNilForEmptyArray() {
        let traits: [Test_Primitives.Test.Trait] = []
        #expect(traits.snapshotRecording == nil)
    }
}
