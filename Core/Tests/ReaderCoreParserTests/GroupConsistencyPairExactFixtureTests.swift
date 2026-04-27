import Foundation
import XCTest
@testable import ReaderCoreParser

final class GroupConsistencyPairExactFixtureTests: XCTestCase {
    private struct RejectExpected: Decodable, Equatable {
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

    private struct FixtureCase {
        let sample: String
        let expectReject: Bool
    }

    private let fixtureCases: [FixtureCase] = [
        .init(sample: "gc_pair_duplicate_hit", expectReject: false),
        .init(sample: "gc_pair_unique_pass", expectReject: false),
        .init(sample: "gc_pair_missing_one_key_reject", expectReject: true),
        .init(sample: "gc_pair_invalid_one_key_reject", expectReject: true),
        .init(sample: "gc_pair_invalid_three_keys_reject", expectReject: true),
        .init(sample: "gc_pair_duplicate_key_names_reject", expectReject: true),
        .init(sample: "gc_pair_stable_ordering", expectReject: false),
        .init(sample: "gc_pair_multiple_duplicate_tuple_groups", expectReject: false)
    ]

    func testFixtureDrivenSamples_matchExpected() throws {
        for testCase in fixtureCases {
            let fixture = try loadFixture(testCase.sample)
            let expectedData = try Data(contentsOf: expectedURL(testCase.sample))

            if testCase.expectReject {
                let expectedReject = try JSONDecoder().decode(RejectExpected.self, from: expectedData)
                XCTAssertThrowsError(
                    try GroupConsistencyPairExactConstraint().evaluate(
                        rule: fixture.rule,
                        records: fixture.records
                    ),
                    "sample \(testCase.sample) should reject"
                ) { error in
                    guard let pairError = error as? GroupConsistencyPairExactError else {
                        return XCTFail("Unexpected error type for \(testCase.sample): \(error)")
                    }
                    let actual = RejectExpected(
                        rejected: true,
                        checkedKeys: pairError.checkedKeys,
                        error: .init(code: pairError.snapshotCode, message: pairError.snapshotMessage)
                    )
                    XCTAssertEqual(actual, expectedReject, "Reject envelope mismatch for \(testCase.sample)")
                }
            } else {
                let expected = try JSONDecoder().decode(GroupConsistencyPairExactResult.self, from: expectedData)
                let actual = try GroupConsistencyPairExactConstraint().evaluate(
                    rule: fixture.rule,
                    records: fixture.records
                )
                XCTAssertEqual(actual, expected, "Result mismatch for \(testCase.sample)")
            }
        }
    }

    private func loadFixture(_ sample: String) throws -> GroupConsistencyPairExactInput {
        let data = try Data(contentsOf: fixtureURL(sample))
        return try JSONDecoder().decode(GroupConsistencyPairExactInput.self, from: data)
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
            .appendingPathComponent("samples/fixtures/group_consistency_pair")
            .appendingPathComponent("\(sample).json")
    }

    private func expectedURL(_ sample: String) -> URL {
        repoRoot()
            .appendingPathComponent("samples/expected/group_consistency_pair")
            .appendingPathComponent("\(sample).json")
    }
}
