import Foundation
import XCTest
@testable import ReaderCoreParser

final class GroupConsistencyTripletExactFixtureTests: XCTestCase {
    private struct RejectEnvelope: Decodable, Equatable {
        let rejected: Bool
        let checkedKeys: [String]
        let error: RejectError

        struct RejectError: Decodable, Equatable {
            let code: String
            let message: String
        }

        enum CodingKeys: String, CodingKey {
            case rejected
            case checkedKeys = "checked_keys"
            case error
        }
    }

    func testTripletDuplicateHit() throws {
        try assertSuccessFixture("gc_triplet_duplicate_hit")
    }

    func testTripletUniquePass() throws {
        try assertSuccessFixture("gc_triplet_unique_pass")
    }

    func testTripletStableOrdering() throws {
        try assertSuccessFixture("gc_triplet_stable_ordering")
    }

    func testTripletMultipleDuplicateTupleGroups() throws {
        try assertSuccessFixture("gc_triplet_multiple_duplicate_tuple_groups")
    }

    func testTripletKeyOrderSensitive() throws {
        try assertSuccessFixture("gc_triplet_key_order_sensitive")
    }

    func testTripletMissingOneKeyReject() throws {
        try assertRejectFixture(
            "gc_triplet_missing_one_key_reject",
            expectedMessagePrefix: "missing required key 'region'"
        )
    }

    func testTripletInvalidTwoKeysReject() throws {
        try assertRejectFixture(
            "gc_triplet_invalid_two_keys_reject",
            expectedMessagePrefix: "rule.keys must contain exactly 3 keys; got 2"
        )
    }

    func testTripletInvalidFourKeysReject() throws {
        try assertRejectFixture(
            "gc_triplet_invalid_four_keys_reject",
            expectedMessagePrefix: "rule.keys must contain exactly 3 keys; got 4"
        )
    }

    func testTripletDuplicateKeyNamesReject() throws {
        try assertRejectFixture(
            "gc_triplet_duplicate_key_names_reject",
            expectedMessagePrefix: "rule.keys must contain 3 distinct keys"
        )
    }

    private func assertSuccessFixture(_ sample: String) throws {
        let fixture = try loadFixture(sample)
        let expectedData = try Data(contentsOf: expectedURL(sample))
        let expected = try JSONDecoder().decode(GroupConsistencyTripletExactResult.self, from: expectedData)

        let actual = try GroupConsistencyTripletExactConstraint().evaluate(
            rule: fixture.rule,
            records: fixture.records
        )

        XCTAssertEqual(actual.pass, expected.pass)
        XCTAssertEqual(actual.checkedKeys, expected.checkedKeys)
        XCTAssertEqual(actual.checkedCount, expected.checkedCount)
        XCTAssertEqual(actual.issueCount, expected.issueCount)
        XCTAssertEqual(actual.issues.count, expected.issues.count)

        for (lhs, rhs) in zip(actual.issues, expected.issues) {
            XCTAssertEqual(lhs.code, rhs.code)
            XCTAssertEqual(lhs.keys, rhs.keys)
            XCTAssertEqual(lhs.values, rhs.values)
            XCTAssertEqual(lhs.message, rhs.message)
            XCTAssertEqual(lhs.evidence.duplicateCount, rhs.evidence.duplicateCount)
            XCTAssertEqual(lhs.evidence.recordIDs, rhs.evidence.recordIDs)
            XCTAssertEqual(lhs.evidence.positions, rhs.evidence.positions)
        }
    }

    private func assertRejectFixture(_ sample: String, expectedMessagePrefix: String) throws {
        let fixture = try loadFixture(sample)
        let expectedData = try Data(contentsOf: expectedURL(sample))
        let expected = try JSONDecoder().decode(RejectEnvelope.self, from: expectedData)

        XCTAssertThrowsError(
            try GroupConsistencyTripletExactConstraint().evaluate(
                rule: fixture.rule,
                records: fixture.records
            )
        ) { error in
            guard let tripletError = error as? GroupConsistencyTripletExactError else {
                return XCTFail("Unexpected error type for \(sample): \(error)")
            }
            XCTAssertEqual(expected.rejected, true)
            XCTAssertEqual(tripletError.checkedKeys, expected.checkedKeys)
            XCTAssertEqual(tripletError.snapshotCode, expected.error.code)
            XCTAssertTrue(
                tripletError.snapshotMessage.hasPrefix(expectedMessagePrefix),
                "Expected message prefix '\(expectedMessagePrefix)' but got '\(tripletError.snapshotMessage)'"
            )
        }
    }

    private func loadFixture(_ sample: String) throws -> GroupConsistencyTripletExactInput {
        let data = try Data(contentsOf: fixtureURL(sample))
        return try JSONDecoder().decode(GroupConsistencyTripletExactInput.self, from: data)
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

    private func expectedURL(_ sample: String) -> URL {
        repoRoot()
            .appendingPathComponent("samples/expected/group_consistency_triplet")
            .appendingPathComponent("\(sample).json")
    }
}
