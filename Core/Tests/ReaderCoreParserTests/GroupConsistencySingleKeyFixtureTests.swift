import Foundation
import XCTest
@testable import ReaderCoreParser

final class GroupConsistencySingleKeyFixtureTests: XCTestCase {
    private struct RejectExpected: Decodable, Equatable {
        let rejected: Bool
        let checkedKey: String
        let error: RejectError

        struct RejectError: Decodable, Equatable {
            let code: String
            let message: String
        }

        enum CodingKeys: String, CodingKey {
            case rejected
            case checkedKey = "checked_key"
            case error
        }
    }

    private struct FixtureCase {
        let sample: String
        let expectReject: Bool
    }

    private let fixtureCases: [FixtureCase] = [
        .init(sample: "gc_single_key_duplicate_hit", expectReject: false),
        .init(sample: "gc_single_key_unique_pass", expectReject: false),
        .init(sample: "gc_single_key_missing_key_reject", expectReject: true),
        .init(sample: "gc_single_key_invalid_rule_reject", expectReject: true),
        .init(sample: "gc_single_key_stable_ordering", expectReject: false),
        .init(sample: "gc_single_key_multiple_duplicate_groups", expectReject: false),
    ]

    func testFixtureDrivenSamples_matchExpected() throws {
        for testCase in fixtureCases {
            let fixture = try loadFixture(testCase.sample)
            let expectedData = try Data(contentsOf: expectedURL(testCase.sample))

            if testCase.expectReject {
                let expectedReject = try JSONDecoder().decode(RejectExpected.self, from: expectedData)
                XCTAssertThrowsError(
                    try GroupConsistencySingleKeyConstraint().evaluate(
                        rule: fixture.rule,
                        records: fixture.records
                    ),
                    "sample \(testCase.sample) should reject"
                ) { error in
                    guard let gcError = error as? GroupConsistencySingleKeyError else {
                        return XCTFail("Unexpected error type for \(testCase.sample): \(error)")
                    }
                    let actual = RejectExpected(
                        rejected: true,
                        checkedKey: gcError.checkedKey,
                        error: .init(code: gcError.snapshotCode, message: gcError.snapshotMessage)
                    )
                    XCTAssertEqual(actual, expectedReject, "Reject envelope mismatch for \(testCase.sample)")
                }
            } else {
                let expected = try JSONDecoder().decode(GroupConsistencySingleKeyResult.self, from: expectedData)
                let actual = try GroupConsistencySingleKeyConstraint().evaluate(
                    rule: fixture.rule,
                    records: fixture.records
                )
                XCTAssertEqual(actual, expected, "Result mismatch for \(testCase.sample)")
            }
        }
    }

    private func loadFixture(_ sample: String) throws -> GroupConsistencySingleKeyInput {
        let data = try Data(contentsOf: fixtureURL(sample))
        return try JSONDecoder().decode(GroupConsistencySingleKeyInput.self, from: data)
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

    private func expectedURL(_ sample: String) -> URL {
        repoRoot()
            .appendingPathComponent("samples/expected/group_consistency")
            .appendingPathComponent("\(sample).json")
    }
}
