import Foundation
import ReaderCoreFoundation

public struct GroupConsistencySingleKeyRule: Codable, Equatable, Sendable {
    public let type: String
    public let key: String

    public init(type: String, key: String) {
        self.type = type
        self.key = key
    }
}

public struct GroupConsistencySingleKeyInput: Codable, Equatable, Sendable {
    public let sampleID: String?
    public let rule: GroupConsistencySingleKeyRule
    public let records: [GroupConsistencySingleKeyRecord]

    enum CodingKeys: String, CodingKey {
        case sampleID = "sample_id"
        case rule
        case records
    }

    public init(sampleID: String?, rule: GroupConsistencySingleKeyRule, records: [GroupConsistencySingleKeyRecord]) {
        self.sampleID = sampleID
        self.rule = rule
        self.records = records
    }
}

public struct GroupConsistencySingleKeyRecord: Codable, Equatable, Sendable {
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

public struct GroupConsistencySingleKeyResult: Codable, Equatable, Sendable {
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
        public let key: String
        public let value: String
        public let message: String
        public let evidence: Evidence
    }

    public let pass: Bool
    public let checkedKey: String
    public let checkedCount: Int
    public let issueCount: Int
    public let issues: [Issue]

    enum CodingKeys: String, CodingKey {
        case pass
        case checkedKey = "checked_key"
        case checkedCount = "checked_count"
        case issueCount = "issue_count"
        case issues
    }
}

public enum GroupConsistencySingleKeyError: Error, Equatable, Sendable {
    case invalidRuleType(actual: String, key: String)
    case emptyRuleKey
    case missingRecordID(index: Int, key: String)
    case missingRequiredKey(index: Int, key: String)
    case nullValue(index: Int, key: String)
    case nonStringValue(index: Int, key: String)

    public var checkedKey: String {
        switch self {
        case .invalidRuleType(_, let key):
            return key
        case .emptyRuleKey:
            return ""
        case .missingRecordID(_, let key),
             .missingRequiredKey(_, let key),
             .nullValue(_, let key),
             .nonStringValue(_, let key):
            return key
        }
    }

    public var snapshotCode: String {
        switch self {
        case .invalidRuleType, .emptyRuleKey:
            return "GROUP_CONSISTENCY_INVALID_RULE"
        case .missingRecordID, .missingRequiredKey, .nullValue, .nonStringValue:
            return "GROUP_CONSISTENCY_INVALID_INPUT"
        }
    }

    public var snapshotMessage: String {
        switch self {
        case .invalidRuleType(let actual, _):
            return "unsupported rule.type '\(actual)'; expected 'single_key_unique'"
        case .emptyRuleKey:
            return "rule.key must be non-empty"
        case .missingRecordID(let index, _):
            return "missing required key 'record_id' at record index \(index)"
        case .missingRequiredKey(let index, let key):
            return "missing required key '\(key)' at record index \(index)"
        case .nullValue(let index, let key):
            return "null value for key '\(key)' at record index \(index)"
        case .nonStringValue(let index, let key):
            return "non-string value for key '\(key)' at record index \(index)"
        }
    }

    public var snapshotMessagePrefix: String {
        switch self {
        case .invalidRuleType(let actual, _):
            return "unsupported rule.type '\(actual)'"
        case .emptyRuleKey:
            return "rule.key must be non-empty"
        case .missingRecordID:
            return "missing required key 'record_id'"
        case .missingRequiredKey(_, let key):
            return "missing required key '\(key)'"
        case .nullValue(_, let key):
            return "null value for key '\(key)'"
        case .nonStringValue(_, let key):
            return "non-string value for key '\(key)'"
        }
    }
}

public struct GroupConsistencySingleKeyConstraint: Sendable {
    public init() {}

    public func evaluate(
        rule: GroupConsistencySingleKeyRule,
        records: [GroupConsistencySingleKeyRecord]
    ) throws -> GroupConsistencySingleKeyResult {
        guard rule.type == "single_key_unique" else {
            throw GroupConsistencySingleKeyError.invalidRuleType(actual: rule.type, key: rule.key)
        }
        guard !rule.key.isEmpty else {
            throw GroupConsistencySingleKeyError.emptyRuleKey
        }

        var groups: [String: (recordIDs: [String], positions: [Int])] = [:]
        var valueOrder: [String] = []

        for (index, record) in records.enumerated() {
            let recordID = try requiredStringValue(
                for: "record_id",
                in: record,
                index: index,
                errorBuilder: { .missingRecordID(index: index, key: rule.key) }
            )
            let value = try requiredStringValue(
                for: rule.key,
                in: record,
                index: index,
                errorBuilder: { .missingRequiredKey(index: index, key: rule.key) }
            )

            if groups[value] == nil {
                valueOrder.append(value)
                groups[value] = (recordIDs: [], positions: [])
            }
            groups[value]?.recordIDs.append(recordID)
            groups[value]?.positions.append(index)
        }

        let issues: [GroupConsistencySingleKeyResult.Issue] = valueOrder.compactMap { value in
            guard let grouped = groups[value], grouped.recordIDs.count > 1 else {
                return nil
            }
            return .init(
                code: "GROUP_DUPLICATE_SINGLE_KEY",
                key: rule.key,
                value: value,
                message: "duplicate value '\(value)' for key '\(rule.key)'",
                evidence: .init(
                    duplicateCount: grouped.recordIDs.count,
                    recordIDs: grouped.recordIDs,
                    positions: grouped.positions
                )
            )
        }

        return .init(
            pass: issues.isEmpty,
            checkedKey: rule.key,
            checkedCount: records.count,
            issueCount: issues.count,
            issues: issues
        )
    }

    private func requiredStringValue(
        for key: String,
        in record: GroupConsistencySingleKeyRecord,
        index: Int,
        errorBuilder: () -> GroupConsistencySingleKeyError
    ) throws -> String {
        guard let raw = record.value(for: key) else {
            throw errorBuilder()
        }
        switch raw {
        case .string(let value):
            return value
        case .null:
            throw GroupConsistencySingleKeyError.nullValue(index: index, key: key)
        case .number, .bool, .object, .array:
            throw GroupConsistencySingleKeyError.nonStringValue(index: index, key: key)
        }
    }
}
