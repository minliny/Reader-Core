import Foundation
import ReaderCoreModels
import ReaderCoreProtocols

public final class NonJSRuleScheduler: RuleScheduler {
    public init() {}
    
    static let simpleTagNames: Set<String> = [
        "a", "abbr", "address", "article", "aside", "audio", "b", "blockquote", "body", "br",
        "button", "canvas", "caption", "cite", "code", "col", "colgroup", "dd", "del", "details",
        "dfn", "dialog", "div", "dl", "dt", "em", "embed", "fieldset", "figcaption", "figure",
        "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header", "hgroup", "hr", "html",
        "i", "iframe", "img", "input", "ins", "kbd", "label", "legend", "li", "link", "main",
        "map", "mark", "math", "menu", "menuitem", "meta", "meter", "nav", "noscript", "object",
        "ol", "optgroup", "option", "output", "p", "param", "pre", "progress", "q", "rb", "rp",
        "rt", "rtc", "ruby", "s", "samp", "script", "section", "select", "small", "source",
        "span", "strong", "sub", "sup", "table", "tbody", "td", "template", "textarea", "tfoot",
        "th", "thead", "time", "title", "tr", "track", "u", "ul", "var", "video", "wbr"
    ]

    public func evaluate(rule: String, data: Data, flow: ParseFlow, source: BookSource) throws -> [String] {
        let trimmedRule = rule.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedRule.isEmpty {
            throw makeError(flow: flow, type: .FIELD_MISSING, reason: "rule_missing", message: "Rule is required for \(flow.rawValue).")
        }

        let stages = parseStages(trimmedRule)
        var current = [String(data: data, encoding: .utf8) ?? ""]
        var hasNonJSStage = false
        var sawJSStage = false

        for stage in stages {
            switch stage.kind {
            case .regex:
                hasNonJSStage = true
                current = try applyRegex(stage.payload, on: current, flow: flow)
            case .jsonpath:
                hasNonJSStage = true
                current = try applyJSONPath(stage.payload, on: current, flow: flow)
            case .css:
                hasNonJSStage = true
                current = try applyCSS(stage.payload, on: current, flow: flow)
            case .xpath:
                hasNonJSStage = true
                current = try applyXPath(stage.payload, on: current, flow: flow)
            case .replace:
                hasNonJSStage = true
                current = try applyReplace(stage.payload, on: current, flow: flow)
            case .js:
                sawJSStage = true
                continue
            case .unsupported:
                throw makeError(flow: flow, type: .RULE_UNSUPPORTED, reason: "rule_kind_unsupported", message: "Unsupported rule kind: \(stage.raw)")
            }
        }

        if !hasNonJSStage || (sawJSStage && current.isEmpty) {
            throw makeError(flow: flow, type: .JS_DEGRADED, reason: "js_rule_skipped_in_non_js_mode", message: "JS-related rule detected and skipped in non-JS mode.")
        }

        if hasSourceJSHints(source) && current.isEmpty {
            throw makeError(flow: flow, type: .JS_DEGRADED, reason: "js_field_detected_without_non_js_output", message: "JS-only source hints detected without non-JS output.")
        }

        return current.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

private enum RuleKind {
    case css
    case xpath
    case jsonpath
    case regex
    case replace
    case js
    case unsupported
}

private struct RuleStage {
    let kind: RuleKind
    let payload: String
    let raw: String
}

private enum SimpleSelector: Equatable {
    case byClass(String)
    case byId(String)
    case byTag(String)
    case byTagAndClass(tag: String, className: String)
}

private extension SimpleSelector {
    static func parse(_ raw: String) -> SimpleSelector? {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }
        guard !input.contains(" ") else { return nil }
        guard !input.contains(">") else { return nil }
        guard !input.contains("+") else { return nil }
        guard !input.contains("[") else { return nil }
        guard !input.contains("]") else { return nil }

        if input.hasPrefix("class.") {
            let ident = String(input.dropFirst(6))
            guard isValidIdent(ident) else { return nil }
            return .byClass(ident)
        }
        if input.hasPrefix("id.") {
            let ident = String(input.dropFirst(3))
            guard isValidIdent(ident) else { return nil }
            return .byId(ident)
        }
        if input.hasPrefix(".") {
            let ident = String(input.dropFirst())
            guard !ident.isEmpty else { return nil }
            guard !ident.contains(".") else { return nil }
            guard isValidIdent(ident) else { return nil }
            return .byClass(ident)
        }
        if input.hasPrefix("#") {
            let ident = String(input.dropFirst())
            guard !ident.isEmpty else { return nil }
            guard !ident.contains("#") else { return nil }
            guard isValidIdent(ident) else { return nil }
            return .byId(ident)
        }
        if let dotIndex = input.firstIndex(of: ".") {
            let tagPart = String(input[..<dotIndex])
            let classPart = String(input[input.index(after: dotIndex)...])
            guard !tagPart.isEmpty else { return nil }
            guard !classPart.isEmpty else { return nil }
            guard isValidTagName(tagPart) else { return nil }
            guard isValidIdent(classPart) else { return nil }
            return .byTagAndClass(tag: tagPart, className: classPart)
        }

        guard isValidTagName(input) else { return nil }
        return .byTag(input)
    }

    private static func isValidIdent(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        for ch in s {
            guard ch.isASCII else { return false }
            guard ch.isLetter || ch.isNumber || ch == "_" || ch == "-" else { return false }
        }
        return true
    }

    private static func isValidTagName(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        guard let first = s.first else { return false }
        guard first.isASCII && first.isLetter else { return false }
        for ch in s.dropFirst() {
            guard ch.isASCII else { return false }
            guard ch.isLetter || ch.isNumber || ch == "-" else { return false }
        }
        return true
    }
}

private extension NonJSRuleScheduler {
    func parseStages(_ rule: String) -> [RuleStage] {
        let parts = rule.split(separator: "|").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return parts.map { part in
            if part.lowercased().hasPrefix("css:") {
                return RuleStage(kind: .css, payload: String(part.dropFirst(4)), raw: part)
            }
            if part.lowercased().hasPrefix("xpath:") {
                return RuleStage(kind: .xpath, payload: String(part.dropFirst(6)), raw: part)
            }
            if part.lowercased().hasPrefix("jsonpath:") {
                return RuleStage(kind: .jsonpath, payload: String(part.dropFirst(9)), raw: part)
            }
            if part.lowercased().hasPrefix("regex:") {
                return RuleStage(kind: .regex, payload: String(part.dropFirst(6)), raw: part)
            }
            if part.lowercased().hasPrefix("replace:") {
                return RuleStage(kind: .replace, payload: String(part.dropFirst(8)), raw: part)
            }
            if part.lowercased().hasPrefix("js:") || part.lowercased().contains("javascript") {
                return RuleStage(kind: .js, payload: part, raw: part)
            }
            // Treat all other rules as CSS selectors (including those with attribute extraction syntax)
            return RuleStage(kind: .css, payload: part, raw: part)
        }
    }

    func applyRegex(_ pattern: String, on inputs: [String], flow: ParseFlow) throws -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_regex_expression", message: "Invalid regex pattern.")
        }
        var output: [String] = []
        for input in inputs {
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            for match in regex.matches(in: input, options: [], range: range) {
                if match.numberOfRanges > 1, let r = Range(match.range(at: 1), in: input) {
                    output.append(String(input[r]))
                } else if let r = Range(match.range(at: 0), in: input) {
                    output.append(String(input[r]))
                }
            }
        }
        return output
    }

    func applyReplace(_ payload: String, on inputs: [String], flow: ParseFlow) throws -> [String] {
        let pair = payload.components(separatedBy: "=>")
        if pair.count != 2 {
            throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_replace_rule", message: "Replace rule should be from=>to.")
        }
        let from = pair[0]
        let to = pair[1]
        return inputs.map { $0.replacingOccurrences(of: from, with: to) }
    }

    func applyCSS(_ selector: String, on inputs: [String], flow: ParseFlow) throws -> [String] {
        var fullSelector = selector.trimmingCharacters(in: .whitespacesAndNewlines)
        if fullSelector.isEmpty {
            throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_css_selector", message: "CSS selector is empty.")
        }
        
        // Check for text filter syntax: "text.XXX" or "parent text.XXX@attr"
        if fullSelector.starts(with: "text.") || fullSelector.contains(" text.") {
            if let textFilter = parseTextFilter(fullSelector) {
                // Validate text filter components
                if let parent = textFilter.parent {
                    if !isValidV2Selector(parent) {
                        throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_parent_selector", message: "Parent selector must be V2 simple selector.")
                    }
                }
                if let attr = textFilter.attribute {
                    let validAttributes = ["href", "src", "content", "text", "html"]
                    if !validAttributes.contains(attr) {
                        throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_attribute", message: "Unsupported attribute: \(attr).")
                    }
                }
                var output: [String] = []
                for input in inputs {
                    output.append(contentsOf: extractByTextFilter(text: textFilter.text, attribute: textFilter.attribute, parent: textFilter.parent, html: input))
                }
                return output
            } else {
                // Invalid text filter syntax, return empty
                return []
            }
        }
        
        // Check for descendant selector syntax: "parent child@attr" or "parent child"
        if let descendant = parseDescendantSelector(fullSelector) {
            // Validate descendant selector components
            if !isValidV2Selector(descendant.parent) {
                throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_parent_selector", message: "Parent selector must be V2 simple selector.")
            }
            if !isValidSimpleTag(descendant.child) {
                throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_child_selector", message: "Child selector must be a simple tag name.")
            }
            if let attr = descendant.attribute {
                let validAttributes = ["href", "src", "content", "text", "html"]
                if !validAttributes.contains(attr) {
                    throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_attribute", message: "Unsupported attribute: \(attr).")
                }
            }
            var output: [String] = []
            for input in inputs {
                output.append(contentsOf: extractByDescendantCSS(parent: descendant.parent, child: descendant.child, attribute: descendant.attribute, html: input))
            }
            return output
        }
        
        // Parse attribute extraction syntax: selector@attr
        let (baseSelector, attribute) = parseAttributeSyntax(fullSelector)
        if let attribute = attribute {
            // Validate attribute
            let validAttributes = ["href", "src", "content", "text", "html"]
            if !validAttributes.contains(attribute) {
                throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_attribute", message: "Unsupported attribute: \(attribute).")
            }
            fullSelector = baseSelector
        }
        
        // Strict grammar: !<index>:<index>:... where each index is a non-negative integer.
        // Grammar: trimming-suffix ::= "!" index-list
        // index-list ::= index (":" index)+
        // index ::= "0" | positive-integer
        // Invalid suffix: empty, leading/trailing colon, consecutive colons, negative, non-digit chars.
        let trimming = parseTrimmingSuffix(fullSelector)
        if let trimming = trimming {
            fullSelector = trimming.selector
        }

        var output: [String] = []
        for input in inputs {
            if let attribute = attribute {
                output.append(contentsOf: extractAttributeBySimpleCSS(selector: fullSelector, attribute: attribute, html: input))
            } else {
                output.append(contentsOf: extractBySimpleCSS(selector: fullSelector, html: input))
            }
        }
        // Apply strict-grammar trimming if suffix was valid.
        if let trimming = trimming {
            var trimmed: [String] = []
            for idx in trimming.indices {
                if output.indices.contains(idx) {
                    trimmed.append(output[idx])
                }
            }
            output = trimmed
        }
        
        return output
    }
    
    struct DescendantSelector {
        let parent: String
        let child: String
        let attribute: String?
    }
    
    func parseDescendantSelector(_ rule: String) -> DescendantSelector? {
        // Check if rule contains exactly one space (descendant selector pattern)
        let parts = rule.split(separator: " ")
        guard parts.count == 2 else { return nil }
        
        let parent = String(parts[0])
        let childPart = String(parts[1])
        
        // Parse attribute from child if present
        let (child, attr) = parseAttributeSyntax(childPart)
        
        return DescendantSelector(parent: parent, child: child, attribute: attr)
    }
    
    func isValidV2Selector(_ selector: String) -> Bool {
        return SimpleSelector.parse(selector) != nil
    }
    
    func isValidSimpleTag(_ tag: String) -> Bool {
        return NonJSRuleScheduler.simpleTagNames.contains(tag.lowercased())
    }
    
    func extractByDescendantCSS(parent: String, child: String, attribute: String?, html: String) -> [String] {
        // First, find parent nodes using V2 selector
        guard let simpleParent = SimpleSelector.parse(parent) else {
            return []
        }
        
        // Get parent HTML content
        let parentHTMLs = extractParentHTMLBySimpleCSS(selector: simpleParent, html: html)
        
        var results: [String] = []
        let escapedChild = NSRegularExpression.escapedPattern(for: child)
        
        for parentHTML in parentHTMLs {
            if let attr = attribute {
                if attr == "text" || attr == "html" {
                    // Extract text or html content from child tag
                    let pattern = "<\(escapedChild)[^>]*>([\\s\\S]*?)</\(escapedChild)>"
                    let matches = regexGroupMatches(pattern: pattern, in: parentHTML, group: 1).map(stripHTMLTags)
                    results.append(contentsOf: matches)
                } else {
                    // Extract attribute from child tag (href, src, content)
                    let attrEscaped = NSRegularExpression.escapedPattern(for: attr)
                    let pattern = "<\(escapedChild)[^>]*\(attrEscaped)=[\"']([^\"']+)[\"'][^>]*>"
                    let matches = regexGroupMatches(pattern: pattern, in: parentHTML, group: 1)
                    results.append(contentsOf: matches)
                }
            } else {
                // Extract text content from child tag
                let pattern = "<\(escapedChild)[^>]*>([\\s\\S]*?)</\(escapedChild)>"
                let matches = regexGroupMatches(pattern: pattern, in: parentHTML, group: 1).map(stripHTMLTags)
                results.append(contentsOf: matches)
            }
        }
        
        return results
    }
    
    func extractParentHTMLBySimpleCSS(selector: SimpleSelector, html: String) -> [String] {
        switch selector {
        case .byClass(let className):
            let cls = NSRegularExpression.escapedPattern(for: className)
            let pattern = "<([a-zA-Z0-9]+)[^>]*class=[\"'][^\"']*\\b\(cls)\\b[^\"']*[\"'][^>]*>([\\s\\S]*?)</\\1>"
            return regexGroupMatches(pattern: pattern, in: html, group: 2)
        case .byId(let id):
            let escaped = NSRegularExpression.escapedPattern(for: id)
            let pattern = "<([a-zA-Z0-9]+)[^>]*id=[\"']\(escaped)[\"'][^>]*>([\\s\\S]*?)</\\1>"
            return regexGroupMatches(pattern: pattern, in: html, group: 2)
        case .byTag(let tag):
            let escaped = NSRegularExpression.escapedPattern(for: tag)
            let pattern = "<\(escaped)[^>]*>([\\s\\S]*?)</\(escaped)>"
            return regexGroupMatches(pattern: pattern, in: html, group: 1)
        case .byTagAndClass(let tag, let className):
            let tagEscaped = NSRegularExpression.escapedPattern(for: tag)
            let clsEscaped = NSRegularExpression.escapedPattern(for: className)
            let pattern = "<\(tagEscaped)[^>]*class=[\"'][^\"']*\\b\(clsEscaped)\\b[^\"']*[\"'][^>]*>([\\s\\S]*?)</\(tagEscaped)>"
            return regexGroupMatches(pattern: pattern, in: html, group: 1)
        }
    }
    
    func parseAttributeSyntax(_ selector: String) -> (String, String?) {
        let parts = selector.components(separatedBy: "@")
        if parts.count == 2 {
            return (parts[0].trimmingCharacters(in: .whitespaces), parts[1].trimmingCharacters(in: .whitespaces))
        }
        return (selector, nil)
    }
    
    struct TextFilter {
        let text: String
        let attribute: String?
        let parent: String?
    }
    
    func parseTextFilter(_ rule: String) -> TextFilter? {
        // Check for parent scoped text filter: "parent text.XXX@attr"
        let parts = rule.split(separator: " ")
        if parts.count == 2 {
            let parent = String(parts[0])
            let textPart = String(parts[1])
            if textPart.starts(with: "text.") {
                // Check if parent is a valid V2 selector (not another text filter)
                if !parent.starts(with: "text.") && SimpleSelector.parse(parent) != nil {
                    let textContent = textPart.dropFirst(5) // Remove "text."
                    let (text, attr) = parseAttributeSyntax(String(textContent))
                    return TextFilter(text: text, attribute: attr, parent: parent)
                }
            }
        } else if parts.count == 1 && rule.starts(with: "text.") {
            // Simple text filter: "text.XXX@attr"
            let textContent = rule.dropFirst(5) // Remove "text."
            let (text, attr) = parseAttributeSyntax(String(textContent))
            return TextFilter(text: text, attribute: attr, parent: nil)
        }
        return nil
    }

    func extractByTextFilter(text: String, attribute: String?, parent: String?, html: String) -> [String] {
        var targetHTML = html

        if let parent = parent {
            if let simpleParent = SimpleSelector.parse(parent) {
                let parentHTMLs = extractParentHTMLBySimpleCSS(selector: simpleParent, html: html)
                if !parentHTMLs.isEmpty {
                    targetHTML = parentHTMLs.joined()
                } else {
                    return []
                }
            } else {
                return []
            }
        }

        let tagPattern = "<([a-zA-Z0-9]+)([^/>]*)(/?>)"
        let endTagPattern = "</([a-zA-Z0-9]+)>"

        var tags: [(tag: String, content: String)] = []

        let tagRegex = try? NSRegularExpression(pattern: tagPattern, options: [])
        let endTagRegex = try? NSRegularExpression(pattern: endTagPattern, options: [])

        guard let tagRegex = tagRegex, let endTagRegex = endTagRegex else {
            return []
        }

        let fullRange = NSRange(targetHTML.startIndex..<targetHTML.endIndex, in: targetHTML)
        let tagMatches = tagRegex.matches(in: targetHTML, options: [], range: fullRange)

        guard let textRange = targetHTML.range(of: text) else {
            return []
        }

        for tagMatch in tagMatches {
            guard let tagRange = Range(tagMatch.range, in: targetHTML) else { continue }
            let tagStr = String(targetHTML[tagRange])

            if tagStr.contains("/>") { continue }

            let tagNameMatches = regexGroupMatches(pattern: "<([a-zA-Z0-9]+)", in: tagStr, group: 1)
            guard let tagName = tagNameMatches.first else { continue }

            var searchRange = NSRange(tagRange.upperBound..<targetHTML.endIndex, in: targetHTML)
            var depth = 1

            while depth > 0 {
                if let endMatch = endTagRegex.firstMatch(in: targetHTML, options: [], range: searchRange),
                   let endRange = Range(endMatch.range, in: targetHTML) {
                    let endStr = String(targetHTML[endRange])
                    let endNameMatches = regexGroupMatches(pattern: "</([a-zA-Z0-9]+)", in: endStr, group: 1)
                    guard let endName = endNameMatches.first else { break }

                    if endName == tagName {
                        if depth == 1 {
                            let contentRange = tagRange.upperBound..<endRange.lowerBound
                            if contentRange.lowerBound <= textRange.lowerBound && contentRange.upperBound >= textRange.upperBound {
                                let fullTag = String(targetHTML[tagRange.lowerBound..<endRange.upperBound])
                                let content = String(targetHTML[contentRange])
                                tags.append((tag: fullTag, content: content))
                            }
                            break
                        } else {
                            depth -= 1
                        }
                    }
                    searchRange = NSRange(endRange.upperBound..<targetHTML.endIndex, in: targetHTML)
                } else {
                    break
                }
            }
        }

        if tags.isEmpty {
            return []
        }

        tags.sort { $0.content.count < $1.content.count }

        let bestMatchTag = tags[0]

        var results: [String] = []

        if let attribute = attribute {
            // Extract attribute from the tag (only from the hit node or its minimal clickable ancestor, no fallback)
            let attrPattern = attribute + "=[\"']([^\"']+)[\"']"
            let attrMatches = regexGroupMatches(pattern: attrPattern, in: bestMatchTag.tag, group: 1)
            if let attrValue = attrMatches.first {
                results.append(attrValue)
            } else {
                var foundValidParent = false
                for tag in tags {
                    if tag.tag.contains(bestMatchTag.tag) && tag.tag != bestMatchTag.tag {
                        if let openingTagEnd = tag.tag.range(of: ">"), let closingTagStart = tag.tag.range(of: "</", options: .backwards) {
                            let tagContent = String(tag.tag[openingTagEnd.upperBound..<closingTagStart.lowerBound])
                            let tagContentTrimmed = tagContent.trimmingCharacters(in: .whitespacesAndNewlines)
                            let bestMatchTrimmed = bestMatchTag.tag.trimmingCharacters(in: .whitespacesAndNewlines)
                            if tagContentTrimmed == bestMatchTrimmed {
                                let parentAttrMatches = regexGroupMatches(pattern: attrPattern, in: tag.tag, group: 1)
                                if let parentAttrValue = parentAttrMatches.first {
                                    results.append(parentAttrValue)
                                    foundValidParent = true
                                    break
                                }
                            }
                        }
                    }
                }
                if !foundValidParent {
                    return []
                }
            }
        } else {
            let strippedContent = stripHTMLTags(bestMatchTag.content)
            let lines = strippedContent.split(separator: "\n")
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.contains(text) {
                    results.append(trimmedLine)
                    break
                }
            }
            if results.isEmpty {
                results.append(strippedContent)
            }
        }

        return results
    }

    func applyXPath(_ expr: String, on inputs: [String], flow: ParseFlow) throws -> [String] {
        let trimmed = expr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_xpath_expression", message: "XPath expression is empty.")
        }
        var output: [String] = []
        for input in inputs {
            output.append(contentsOf: extractBySimpleXPath(expression: trimmed, html: input))
        }
        return output
    }

    func applyJSONPath(_ path: String, on inputs: [String], flow: ParseFlow) throws -> [String] {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.hasPrefix("$.") {
            throw makeError(flow: flow, type: .RULE_INVALID, reason: "invalid_jsonpath_expression", message: "JSONPath must start with $.")
        }
        var output: [String] = []
        for input in inputs {
            guard let data = input.data(using: .utf8) else {
                continue
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) else {
                throw makeError(flow: flow, type: .JSON_INVALID, reason: "malformed_json_payload", message: "Input is not valid JSON for JSONPath.")
            }
            let values = evaluateSimpleJSONPath(trimmed, json: json)
            output.append(contentsOf: values)
        }
        return output
    }

    func evaluateSimpleJSONPath(_ path: String, json: Any) -> [String] {
        let tokens = tokenizeJSONPath(path)
        var current: [Any] = [json]
        for token in tokens {
            var next: [Any] = []
            for node in current {
                if case .key(let key) = token, let dict = node as? [String: Any], let value = dict[key] {
                    next.append(value)
                } else if case .index(let idx) = token, let array = node as? [Any], array.indices.contains(idx) {
                    next.append(array[idx])
                }
            }
            current = next
        }
        return current.compactMap { anyToString($0) }
    }

    func tokenizeJSONPath(_ path: String) -> [JSONPathToken] {
        let body = String(path.dropFirst(2))
        var tokens: [JSONPathToken] = []
        for segment in body.split(separator: ".") {
            let s = String(segment)
            if let l = s.firstIndex(of: "["), let r = s.firstIndex(of: "]"), l < r {
                let key = String(s[..<l])
                if !key.isEmpty {
                    tokens.append(.key(key))
                }
                let idxText = String(s[s.index(after: l)..<r])
                if let idx = Int(idxText) {
                    tokens.append(.index(idx))
                }
            } else {
                tokens.append(.key(s))
            }
        }
        return tokens
    }

    /// Parses the `!` trimming suffix from a CSS selector using strict grammar.
    ///
    /// Grammar: `<selector>!<index>:<index>:...`
    /// - Each `<index>` must be a non-negative decimal integer (no sign, no leading zeros).
    /// - Must have at least one index.
    /// - No leading/trailing/consecutive colons.
    ///
    /// - Parameters:
    ///   - selector: The full selector string to parse.
    /// - Returns: `(selector, [indices])` if grammar matches, `nil` otherwise.
    ///
    /// Invalid examples (returns nil):
    ///   - `.chapter!`         → empty index
    ///   - `.chapter!:`        → leading colon
    ///   - `.chapter!0:`       → trailing colon
    ///   - `.chapter!0::1`     → consecutive colons
    ///   - `.chapter!-1`       → negative index
    ///   - `.chapter!1a`      → non-digit character
    private func parseTrimmingSuffix(_ selector: String) -> (selector: String, indices: [Int])? {
        guard let exclamationIndex = selector.lastIndex(of: "!") else {
            return nil
        }

        let cssPart = String(selector[..<exclamationIndex])
        guard !cssPart.isEmpty else { return nil }

        let indexPart = String(selector[selector.index(after: exclamationIndex)...])

        // Grammar rule: index-list ::= index (":" index)+
        // index ::= "0" | positive-integer
        guard !indexPart.isEmpty else { return nil }
        guard !indexPart.hasPrefix(":") else { return nil }
        guard !indexPart.hasSuffix(":") else { return nil }
        guard !indexPart.contains("::") else { return nil }

        let segments = indexPart.split(separator: ":")
        guard segments.count >= 1, !segments.contains(where: { $0.isEmpty }) else {
            return nil
        }

        var indices: [Int] = []
        for segment in segments {
            // Each segment must be all digits (no sign, no letters)
            guard segment.allSatisfy({ $0.isNumber }) else { return nil }
            guard let idx = Int(segment), idx >= 0 else { return nil }
            indices.append(idx)
        }

        guard !indices.isEmpty else { return nil }

        return (cssPart, indices)
    }

    func parseSimpleSelector(_ raw: String) -> SimpleSelector? {
        SimpleSelector.parse(raw)
    }

    func extractBySimpleCSS(selector: String, html: String) -> [String] {
        guard let simple = SimpleSelector.parse(selector) else {
            return []
        }
        switch simple {
        case .byClass(let className):
            let cls = NSRegularExpression.escapedPattern(for: className)
            let pattern = "<([a-zA-Z0-9]+)[^>]*class=[\"'][^\"']*\\b\(cls)\\b[^\"']*[\"'][^>]*>([\\s\\S]*?)</\\1>"
            return regexGroupMatches(pattern: pattern, in: html, group: 2).map(stripHTMLTags)
        case .byId(let id):
            let escaped = NSRegularExpression.escapedPattern(for: id)
            let pattern = "<([a-zA-Z0-9]+)[^>]*id=[\"']\(escaped)[\"'][^>]*>([\\s\\S]*?)</\\1>"
            return regexGroupMatches(pattern: pattern, in: html, group: 2).map(stripHTMLTags)
        case .byTag(let tag):
            let escaped = NSRegularExpression.escapedPattern(for: tag)
            let pattern = "<\(escaped)[^>]*>([\\s\\S]*?)</\(escaped)>"
            return regexGroupMatches(pattern: pattern, in: html, group: 1).map(stripHTMLTags)
        case .byTagAndClass(let tag, let className):
            let tagEscaped = NSRegularExpression.escapedPattern(for: tag)
            let clsEscaped = NSRegularExpression.escapedPattern(for: className)
            let pattern = "<\(tagEscaped)[^>]*class=[\"'][^\"']*\\b\(clsEscaped)\\b[^\"']*[\"'][^>]*>([\\s\\S]*?)</\(tagEscaped)>"
            return regexGroupMatches(pattern: pattern, in: html, group: 1).map(stripHTMLTags)
        }
    }
    
    func extractAttributeBySimpleCSS(selector: String, attribute: String, html: String) -> [String] {
        guard let simple = SimpleSelector.parse(selector) else {
            return []
        }
        
        switch simple {
        case .byClass(let className):
            let cls = NSRegularExpression.escapedPattern(for: className)
            let attr = NSRegularExpression.escapedPattern(for: attribute)
            let pattern = "<([a-zA-Z0-9]+)[^>]*class=[\"'][^\"']*\\b\(cls)\\b[^\"']*[\"'][^>]*\(attr)=[\"']([^\"']+)[\"'][^>]*>"
            return regexGroupMatches(pattern: pattern, in: html, group: 2)
        case .byId(let id):
            let escaped = NSRegularExpression.escapedPattern(for: id)
            let attr = NSRegularExpression.escapedPattern(for: attribute)
            let pattern = "<([a-zA-Z0-9]+)[^>]*id=[\"']\(escaped)[\"'][^>]*\(attr)=[\"']([^\"']+)[\"'][^>]*>"
            return regexGroupMatches(pattern: pattern, in: html, group: 2)
        case .byTag(let tag):
            let escaped = NSRegularExpression.escapedPattern(for: tag)
            let attr = NSRegularExpression.escapedPattern(for: attribute)
            let pattern = "<\(escaped)[^>]*\(attr)=[\"']([^\"']+)[\"'][^>]*>"
            return regexGroupMatches(pattern: pattern, in: html, group: 1)
        case .byTagAndClass(let tag, let className):
            let tagEscaped = NSRegularExpression.escapedPattern(for: tag)
            let clsEscaped = NSRegularExpression.escapedPattern(for: className)
            let attr = NSRegularExpression.escapedPattern(for: attribute)
            let pattern = "<\(tagEscaped)[^>]*class=[\"'][^\"']*\\b\(clsEscaped)\\b[^\"']*[\"'][^>]*\(attr)=[\"']([^\"']+)[\"'][^>]*>"
            return regexGroupMatches(pattern: pattern, in: html, group: 1)
        }
    }

    func extractBySimpleXPath(expression: String, html: String) -> [String] {
        if expression.hasPrefix("//"), expression.hasSuffix("/text()") {
            let tag = String(expression.dropFirst(2).dropLast(7))
            let escapedTag = NSRegularExpression.escapedPattern(for: tag)
            let pattern = "<\(escapedTag)[^>]*>([\\s\\S]*?)</\(escapedTag)>"
            return regexGroupMatches(pattern: pattern, in: html, group: 1).map(stripHTMLTags)
        }
        if expression.hasPrefix("//"), expression.contains("/@") {
            let parts = expression.dropFirst(2).split(separator: "/@")
            if parts.count == 2 {
                let tag = NSRegularExpression.escapedPattern(for: String(parts[0]))
                let attr = NSRegularExpression.escapedPattern(for: String(parts[1]))
                let pattern = "<\(tag)[^>]*\(attr)=[\"']([^\"']+)[\"'][^>]*>"
                return regexGroupMatches(pattern: pattern, in: html, group: 1)
            }
        }
        return []
    }

    func regexGroupMatches(pattern: String, in text: String, group: Int) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard match.numberOfRanges > group, let r = Range(match.range(at: group), in: text) else {
                return nil
            }
            return String(text[r])
        }
    }

    func stripHTMLTags(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func hasSourceJSHints(_ source: BookSource) -> Bool {
        let jsKeys = ["loginCheckJs", "coverDecodeJs", "js", "javaScript"]
        let hasUnknownJS = source.unknownFields.keys.contains { key in
            jsKeys.contains { key.lowercased().contains($0.lowercased()) }
        }
        let hasRuleJS = [source.ruleSearch, source.ruleBookInfo, source.ruleToc, source.ruleContent]
            .compactMap { $0?.lowercased() }
            .contains { $0.contains("js:") || $0.contains("javascript") }
        return hasUnknownJS || hasRuleJS
    }

    func makeError(flow: ParseFlow, type: FailureType, reason: String, message: String) -> ReaderError {
        ReaderError(
            code: .parsingFailed,
            message: message,
            failure: FailureRecord(type: type, reason: reason),
            context: [
                "flow": flow.rawValue,
                "engine": "non_js"
            ]
        )
    }

    enum JSONPathToken {
        case key(String)
        case index(Int)
    }

    func anyToString(_ value: Any) -> String? {
        if let str = value as? String {
            return str
        }
        if let num = value as? NSNumber {
            return num.stringValue
        }
        if JSONSerialization.isValidJSONObject(value), let data = try? JSONSerialization.data(withJSONObject: value), let text = String(data: data, encoding: .utf8) {
            return text
        }
        return nil
    }
}
