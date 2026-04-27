import Foundation
import XCTest
@testable import ReaderCoreParser

final class GroupConsistencySingleKeySnapshotTests: XCTestCase {
    private struct IssueSnapshot: Decodable, Encodable, Equatable {
        let code: String
        let key: String
        let value: String
        let evidence: GroupConsistencySingleKeyResult.Evidence
    }

    private struct ResultSnapshot: Decodable, Encodable, Equatable {
        let pass: Bool
        let checkedKey: String
        let checkedCount: Int
        let issueCount: Int
        let issues: [IssueSnapshot]

        enum CodingKeys: String, CodingKey {
            case pass
            case checkedKey = "checked_key"
            case checkedCount = "checked_count"
            case issueCount = "issue_count"
            case issues
        }
    }

    private struct OrderingSnapshot: Decodable, Encodable, Equatable {
        let issueValues: [String]
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
        let issueValues: [String]
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
        let checkedKey: String
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
            case checkedKey = "checked_key"
            case error
        }
    }

    func testDuplicateHitSnapshot() throws {
        let result = try runSample("gc_single_key_duplicate_hit")
        let snapshot = ResultSnapshot(
            pass: result.pass,
            checkedKey: result.checkedKey,
            checkedCount: result.checkedCount,
            issueCount: result.issueCount,
            issues: result.issues.map {
                .init(code: $0.code, key: $0.key, value: $0.value, evidence: $0.evidence)
            }
        )
        let expected = try loadSnapshot("gc_single_key_duplicate_hit.snapshot.json", as: ResultSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testUniquePassSnapshot() throws {
        let result = try runSample("gc_single_key_unique_pass")
        let snapshot = ResultSnapshot(
            pass: result.pass,
            checkedKey: result.checkedKey,
            checkedCount: result.checkedCount,
            issueCount: result.issueCount,
            issues: []
        )
        let expected = try loadSnapshot("gc_single_key_unique_pass.snapshot.json", as: ResultSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testStableOrderingSnapshot() throws {
        let result = try runSample("gc_single_key_stable_ordering")
        let snapshot = OrderingSnapshot(
            issueValues: result.issues.map(\.value),
            issueRecordIDs: result.issues.map { $0.evidence.recordIDs },
            issuePositions: result.issues.map { $0.evidence.positions }
        )
        let expected = try loadSnapshot("gc_single_key_stable_ordering.snapshot.json", as: OrderingSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testMultipleGroupsSnapshot() throws {
        let result = try runSample("gc_single_key_multiple_duplicate_groups")
        let snapshot = MultiGroupSnapshot(
            issueCount: result.issueCount,
            issueValues: result.issues.map(\.value),
            duplicateCounts: result.issues.map { $0.evidence.duplicateCount },
            issueRecordIDs: result.issues.map { $0.evidence.recordIDs },
            issuePositions: result.issues.map { $0.evidence.positions }
        )
        let expected = try loadSnapshot("gc_single_key_multiple_duplicate_groups.snapshot.json", as: MultiGroupSnapshot.self)
        XCTAssertEqual(snapshot, expected)
    }

    func testMissingKeyRejectSnapshot() throws {
        try assertRejectSnapshot(
            sample: "gc_single_key_missing_key_reject",
            snapshotFile: "gc_single_key_missing_key_reject.snapshot.json"
        )
    }

    func testInvalidRuleRejectSnapshot() throws {
        try assertRejectSnapshot(
            sample: "gc_single_key_invalid_rule_reject",
            snapshotFile: "gc_single_key_invalid_rule_reject.snapshot.json"
        )
    }

    private func runSample(_ sample: String) throws -> GroupConsistencySingleKeyResult {
        let fixture = try loadFixture(sample)
        return try GroupConsistencySingleKeyConstraint().evaluate(
            rule: fixture.rule,
            records: fixture.records
        )
    }

    private func assertRejectSnapshot(sample: String, snapshotFile: String) throws {
        let fixture = try loadFixture(sample)
        let expected = try loadSnapshot(snapshotFile, as: RejectSnapshot.self)

        XCTAssertThrowsError(
            try GroupConsistencySingleKeyConstraint().evaluate(
                rule: fixture.rule,
                records: fixture.records
            )
        ) { error in
            guard let gcError = error as? GroupConsistencySingleKeyError else {
                return XCTFail("Unexpected error type for \(sample): \(error)")
            }
            let actual = RejectSnapshot(
                rejected: true,
                checkedKey: gcError.checkedKey,
                error: .init(code: gcError.snapshotCode, messagePrefix: gcError.snapshotMessagePrefix)
            )
            XCTAssertEqual(actual, expected)
        }
    }

    private func loadFixture(_ sample: String) throws -> GroupConsistencySingleKeyInput {
        let data = try Data(contentsOf: fixtureURL(sample))
        return try JSONDecoder().decode(GroupConsistencySingleKeyInput.self, from: data)
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
            .appendingPathComponent("samples/fixtures/group_consistency")
            .appendingPathComponent("\(sample).json")
    }

    private func snapshotURL(_ file: String) -> URL {
        repoRoot()
            .appendingPathComponent("samples/expected/group_consistency/snapshots")
            .appendingPathComponent(file)
    }
}
