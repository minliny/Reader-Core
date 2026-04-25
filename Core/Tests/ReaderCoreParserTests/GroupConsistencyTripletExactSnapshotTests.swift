import Foundation
import XCTest
@testable import ReaderCoreParser

final class GroupConsistencyTripletExactSnapshotTests: XCTestCase {
    private struct IssueSnapshot: Decodable, Encodable, Equatable {
        let code: String
        let keys: [String]
        let values: [String]
        let evidence: GroupConsistencyTripletExactResult.Evidence
    }

    private struct ResultSnapshot: Decodable, Encodable, Equatable {
        let pass: Bool
        let checkedKeys: [String]
        let checkedCount: Int
        let issueCount: Int
        let issues: [IssueSnapshot]

        enum CodingKeys: String, CodingKey {
            case pass
            case checkedKeys = "checked_keys"
            case checkedCount = "checked_count"
            case issueCount = "issue_count"
            case issues
        }
    }

    private struct OrderingSnapshot: Decodable, Encodable, Equatable {
        let issueValues: [[String]]
        let issueRecordIDs: [[String]]
        let issuePositions: [[Int]]

        enum CodingKeys: String, CodingKey {
            case issueValues = "issue_values"
            case issueRecordIDs = "issue_record_ids"
            case issuePositions = "issue_positions"
        }
    }

    private struct MultiGroupSnapshot: Decodable, Encodable, Equatable {
        let issueCount: Int
        let issueValues: [[String]]
        let duplicateCounts: [Int]
        let issueRecordIDs: [[String]]
        let issuePositions: [[Int]]

        enum CodingKeys: String, CodingKey {
            case issueCount = "issue_count"
            case issueValues = "issue_values"
            case duplicateCounts = "duplicate_counts"
            case issueRecordIDs = "issue_record_ids"
            case issuePositions = "issue_positions"
        }
    }

    private struct RejectSnapshot: Decodable, Encodable, Equatable {
        let rejected: Bool
        let checkedKeys: [String]
        let error: ErrorSnapshot

        struct ErrorSnapshot: Decodable, Encodable, Equatable {
            let code: String
            let messagePrefix: String

            enum CodingKeys: String, CodingKey {
                case code
                case messagePrefix = "message_prefix"
            }
        }

        enum CodingKeys: String, CodingKey {
            case rejected
            case checkedKeys = "checked_keys"
            case error
        }
    }

    func testDuplicateHitSnapshot() throws {
        let result = try runSample("gc_triplet_duplicate_hit")
        let snapshot = ResultSnapshot(
            pass: result.pass,
            checkedKeys: result.checkedKeys,
            checkedCount: result.checkedCount,
            issueCount: result.issueCount,
            issues: result.issues.map {
                .init(code: $0.code, keys: $0.keys, values: $0.values, evidence: $0.evidence)
            }
        )
        let expected = try loadSnapshot("gc_triplet_duplicate_hit.snapshot.json", as: ResultSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testUniquePassSnapshot() throws {
        let result = try runSample("gc_triplet_unique_pass")
        let snapshot = ResultSnapshot(
            pass: result.pass,
            checkedKeys: result.checkedKeys,
            checkedCount: result.checkedCount,
            issueCount: result.issueCount,
            issues: []
        )
        let expected = try loadSnapshot("gc_triplet_unique_pass.snapshot.json", as: ResultSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testStableOrderingSnapshot() throws {
        let result = try runSample("gc_triplet_stable_ordering")
        let snapshot = OrderingSnapshot(
            issueValues: result.issues.map(\.values),
            issueRecordIDs: result.issues.map { $0.evidence.recordIDs },
            issuePositions: result.issues.map { $0.evidence.positions }
        )
        let expected = try loadSnapshot("gc_triplet_stable_ordering.snapshot.json", as: OrderingSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testMultipleGroupsSnapshot() throws {
        let result = try runSample("gc_triplet_multiple_duplicate_tuple_groups")
        let snapshot = MultiGroupSnapshot(
            issueCount: result.issueCount,
            issueValues: result.issues.map(\.values),
            duplicateCounts: result.issues.map { $0.evidence.duplicateCount },
            issueRecordIDs: result.issues.map { $0.evidence.recordIDs },
            issuePositions: result.issues.map { $0.evidence.positions }
        )
        let expected = try loadSnapshot("gc_triplet_multiple_duplicate_tuple_groups.snapshot.json", as: MultiGroupSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testKeyOrderSensitiveSnapshot() throws {
        let result = try runSample("gc_triplet_key_order_sensitive")
        let snapshot = ResultSnapshot(
            pass: result.pass,
            checkedKeys: result.checkedKeys,
            checkedCount: result.checkedCount,
            issueCount: result.issueCount,
            issues: result.issues.map {
                .init(code: $0.code, keys: $0.keys, values: $0.values, evidence: $0.evidence)
            }
        )
        let expected = try loadSnapshot("gc_triplet_key_order_sensitive.snapshot.json", as: ResultSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testMissingOneKeyRejectSnapshot() throws {
        try assertRejectSnapshot(
            sample: "gc_triplet_missing_one_key_reject",
            snapshotFile: "gc_triplet_missing_one_key_reject.snapshot.json"
        )
    }

    func testInvalidTwoKeysRejectSnapshot() throws {
        try assertRejectSnapshot(
            sample: "gc_triplet_invalid_two_keys_reject",
            snapshotFile: "gc_triplet_invalid_two_keys_reject.snapshot.json"
        )
    }

    func testInvalidFourKeysRejectSnapshot() throws {
        try assertRejectSnapshot(
            sample: "gc_triplet_invalid_four_keys_reject",
            snapshotFile: "gc_triplet_invalid_four_keys_reject.snapshot.json"
        )
    }

    func testDuplicateKeyNamesRejectSnapshot() throws {
        try assertRejectSnapshot(
            sample: "gc_triplet_duplicate_key_names_reject",
            snapshotFile: "gc_triplet_duplicate_key_names_reject.snapshot.json"
        )
    }

    private func runSample(_ sample: String) throws -> GroupConsistencyTripletExactResult {
        let fixture = try loadFixture(sample)
        return try GroupConsistencyTripletExactConstraint().evaluate(
            rule: fixture.rule,
            records: fixture.records
        )
    }

    private func assertRejectSnapshot(sample: String, snapshotFile: String) throws {
        let fixture = try loadFixture(sample)
        let expected = try loadSnapshot(snapshotFile, as: RejectSnapshot.self)

        XCTAssertThrowsError(
            try GroupConsistencyTripletExactConstraint().evaluate(
                rule: fixture.rule,
                records: fixture.records
            )
        ) { error in
            guard let tripletError = error as? GroupConsistencyTripletExactError else {
                return XCTFail("Unexpected error type for \(sample): \(error)")
            }
            let actual = RejectSnapshot(
                rejected: true,
                checkedKeys: tripletError.checkedKeys,
                error: .init(code: tripletError.snapshotCode, messagePrefix: tripletError.snapshotMessagePrefix)
            )
            XCTAssertEqual(actual, expected)
        }
    }

    private func loadFixture(_ sample: String) throws -> GroupConsistencyTripletExactInput {
        let data = try Data(contentsOf: fixtureURL(sample))
        return try JSONDecoder().decode(GroupConsistencyTripletExactInput.self, from: data)
    }

    private func loadSnapshot<T: Decodable>(_ file: String, as type: T.Type) throws -> T {
        let data = try Data(contentsOf: snapshotURL(file))
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func fixtureURL(_ sample: String) -> URL {
        repoRoot()
            .appendingPathComponent("samples/fixtures/group_consistency_triplet")
            .appendingPathComponent("\(sample).json")
    }

    private func snapshotURL(_ file: String) -> URL {
        repoRoot()
            .appendingPathComponent("samples/expected/group_consistency_triplet/snapshots")
            .appendingPathComponent(file)
    }
}
