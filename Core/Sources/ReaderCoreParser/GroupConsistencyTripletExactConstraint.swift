import Foundation
import ReaderCoreFoundation

public struct GroupConsistencyTripletExactRule: Codable, Equatable, Sendable {
    public let type: String
    public let keys: [String]

    public init(type: String, keys: [String]) {
        self.type = type
        self.keys = keys
    }
}

public struct GroupConsistencyTripletExactInput: Codable, Equatable, Sendable {
    public let sampleID: String?
    public let rule: GroupConsistencyTripletExactRule
    public let records: [GroupConsistencyTripletExactRecord]

    enum CodingKeys: String, CodingKey {
        case sampleID = "sample_id"
        case rule
        case records
    }

    public init(sampleID: String?, rule: GroupConsistencyTripletExactRule, records: [GroupConsistencyTripletExactRecord]) {
        self.sampleID = sampleID
        self.rule = rule
        self.records = records
    }
}

public struct GroupConsistencyTripletExactRecord: Codable, Equatable, Sendable {
    public let fields: [String: JSONValue]

    public init(fields: [String: JSONValue]) {
        self.fields = fields
    }

    public func value(for key: String) -> JSONValue? {
        fields[key]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.fields = try container.decode([String: JSONValue].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fields)
    }
}

public struct GroupConsistencyTripletExactResult: Codable, Equatable, Sendable {
    public struct Evidence: Codable, Equatable, Sendable {
        public let duplicateCount: Int
        public let recordIDs: [String]
        public let positions: [Int]

        enum CodingKeys: String, CodingKey {
            case duplicateCount = "duplicate_count"
            case recordIDs = "record_ids"
            case positions
        }
    }

    public struct Issue: Codable, Equatable, Sendable {
        public let code: String
        public let keys: [String]
        public let values: [String]
        public let message: String
        public let evidence: Evidence
    }

    public let pass: Bool
    public let checkedKeys: [String]
    public let checkedCount: Int
    public let issueCount: Int
    public let issues: [Issue]

    enum CodingKeys: String, CodingKey {
        case pass
        case checkedKeys = "checked_keys"
        case checkedCount = "checked_count"
        case issueCount = "issue_count"
        case issues
    }
}

public enum GroupConsistencyTripletExactError: Error, Equatable, Sendable {
    case invalidRuleType(actual: String, keys: [String])
    case invalidKeysCount(actual: Int, keys: [String])
    case duplicateKeyNames(key: String, keys: [String])
    case missingRecordID(index: Int, keys: [String])
    case missingRequiredKey(index: Int, key: String, keys: [String])
    case nullValue(index: Int, key: String, keys: [String])
    case nonStringValue(index: Int, key: String, keys: [String])

    public var checkedKeys: [String] {
        switch self {
        case .invalidRuleType(_, let keys),
             .invalidKeysCount(_, let keys),
             .duplicateKeyNames(_, let keys),
             .missingRecordID(_, let keys),
             .missingRequiredKey(_, _, let keys),
             .nullValue(_, _, let keys),
             .nonStringValue(_, _, let keys):
            return keys
        }
    }

    public var snapshotCode: String {
        "RULE_INVALID"
    }

    public var snapshotMessage: String {
        switch self {
        case .invalidRuleType(let actual, _):
            return "unsupported rule.type '\(actual)'; expected 'multi_key_triplet_unique'"
        case .invalidKeysCount(let actual, _):
            return "rule.keys must contain exactly 3 keys; got \(actual)"
        case .duplicateKeyNames(let key, _):
            return "rule.keys must contain 3 distinct keys; got duplicate key '\(key)'"
        case .missingRecordID(let index, _):
            return "missing required key 'record_id' at record index \(index)"
        case .missingRequiredKey(let index, let key, _):
            return "missing required key '\(key)' at record index \(index)"
        case .nullValue(let index, let key, _):
            return "null value for key '\(key)' at record index \(index)"
        case .nonStringValue(let index, let key, _):
            return "non-string value for key '\(key)' at record index \(index)"
        }
    }

    public var snapshotMessagePrefix: String {
        switch self {
        case .invalidRuleType(let actual, _):
            return "unsupported rule.type '\(actual)'"
        case .invalidKeysCount(let actual, _):
            return "rule.keys must contain exactly 3 keys; got \(actual)"
        case .duplicateKeyNames:
            return "rule.keys must contain 3 distinct keys"
        case .missingRecordID:
            return "missing required key 'record_id'"
        case .missingRequiredKey(_, let key, _):
            return "missing required key '\(key)'"
        case .nullValue(_, let key, _):
            return "null value for key '\(key)'"
        case .nonStringValue(_, let key, _):
            return "non-string value for key '\(key)'"
        }
    }
}

public struct GroupConsistencyTripletExactConstraint: Sendable {
    public init() {}

    public func evaluate(
        rule: GroupConsistencyTripletExactRule,
        records: [GroupConsistencyTripletExactRecord]
    ) throws -> GroupConsistencyTripletExactResult {
        guard rule.type == "multi_key_triplet_unique" else {
            throw GroupConsistencyTripletExactError.invalidRuleType(actual: rule.type, keys: rule.keys)
        }
        guard rule.keys.count == 3 else {
            throw GroupConsistencyTripletExactError.invalidKeysCount(actual: rule.keys.count, keys: rule.keys)
        }
        if let duplicateKey = firstDuplicateKey(in: rule.keys) {
            throw GroupConsistencyTripletExactError.duplicateKeyNames(key: duplicateKey, keys: rule.keys)
        }

        struct TupleKey: Hashable {
            let first: String
            let second: String
            let third: String

            var values: [String] { [first, second, third] }
        }

        var groups: [TupleKey: (recordIDs: [String], positions: [Int])] = [:]
        var tupleOrder: [TupleKey] = []

        for (index, record) in records.enumerated() {
            let recordID = try requiredStringValue(
                for: "record_id",
                in: record,
                index: index,
                keys: rule.keys
            )
            let firstValue = try requiredStringValue(
                for: rule.keys[0],
                in: record,
                index: index,
                keys: rule.keys
            )
            let secondValue = try requiredStringValue(
                for: rule.keys[1],
                in: record,
                index: index,
                keys: rule.keys
            )
            let thirdValue = try requiredStringValue(
                for: rule.keys[2],
                in: record,
                index: index,
                keys: rule.keys
            )

            let tuple = TupleKey(first: firstValue, second: secondValue, third: thirdValue)
            if groups[tuple] == nil {
                tupleOrder.append(tuple)
                groups[tuple] = (recordIDs: [], positions: [])
            }
            groups[tuple]?.recordIDs.append(recordID)
            groups[tuple]?.positions.append(index)
        }

        let issues: [GroupConsistencyTripletExactResult.Issue] = tupleOrder.compactMap { tuple in
            guard let grouped = groups[tuple], grouped.recordIDs.count > 1 else {
                return nil
            }
            return .init(
                code: "GROUP_DUPLICATE_MULTI_KEY_TRIPLET",
                keys: rule.keys,
                values: tuple.values,
                message: "duplicate tuple [\(quotedList(tuple.values))] for keys [\(quotedList(rule.keys))]",
                evidence: .init(
                    duplicateCount: grouped.recordIDs.count,
                    recordIDs: grouped.recordIDs,
                    positions: grouped.positions
                )
            )
        }

        return .init(
            pass: issues.isEmpty,
            checkedKeys: rule.keys,
            checkedCount: records.count,
            issueCount: issues.count,
            issues: issues
        )
    }

    private func firstDuplicateKey(in keys: [String]) -> String? {
        var seen: Set<String> = []
        for key in keys {
            if seen.contains(key) {
                return key
            }
            seen.insert(key)
        }
        return nil
    }

    private func requiredStringValue(
        for key: String,
        in record: GroupConsistencyTripletExactRecord,
        index: Int,
        keys: [String]
    ) throws -> String {
        guard let raw = record.value(for: key) else {
            if key == "record_id" {
                throw GroupConsistencyTripletExactError.missingRecordID(index: index, keys: keys)
            }
            throw GroupConsistencyTripletExactError.missingRequiredKey(index: index, key: key, keys: keys)
        }
        switch raw {
        case .string(let value):
            return value
        case .null:
            throw GroupConsistencyTripletExactError.nullValue(index: index, key: key, keys: keys)
        case .number, .bool, .object, .array:
            throw GroupConsistencyTripletExactError.nonStringValue(index: index, key: key, keys: keys)
        }
    }

    private func quotedList(_ values: [String]) -> String {
        values.map { "'\($0)'" }.joined(separator: ",")
    }
}
