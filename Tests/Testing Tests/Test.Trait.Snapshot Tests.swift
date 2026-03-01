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
    func snapshotWitnessKeyStoresRecordingMode() {
        for mode in Test_Primitives.Test.Snapshot.Recording.allCases {
            var collection = Test_Primitives.Test.Trait.Collection()
            collection.snapshotRecording = mode
            #expect(collection.snapshotRecording == mode)
        }
    }

    @Testing.Test
    func snapshotRecordingExtractsFromCollection() {
        var collection = Test_Primitives.Test.Trait.Collection()
        collection.snapshotRecording = .all
        #expect(collection.snapshotRecording == .all)
    }

    @Testing.Test
    func snapshotRecordingOverwritesTakesLast() {
        var collection = Test_Primitives.Test.Trait.Collection()
        collection.snapshotRecording = .never
        collection.snapshotRecording = .all
        #expect(collection.snapshotRecording == .all)
    }
}

// MARK: - EdgeCase

extension Test_Primitives.Test.Trait.SnapshotTest.EdgeCase {
    @Testing.Test
    func snapshotRecordingReturnsNilWhenNotSet() {
        let collection = Test_Primitives.Test.Trait.Collection()
        #expect(collection.snapshotRecording == nil)
    }

    @Testing.Test
    func snapshotRecordingClearsWhenSetToNil() {
        var collection = Test_Primitives.Test.Trait.Collection()
        collection.snapshotRecording = .all
        collection.snapshotRecording = nil
        #expect(collection.snapshotRecording == nil)
    }
}
