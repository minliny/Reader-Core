import XCTest
import ReaderCoreParser
import ReaderCoreModels

final class DescendantSelectorMinimalTests: XCTestCase {
    
    private var scheduler: NonJSRuleScheduler!
    private var bookSource: BookSource!
    
    override func setUp() {
        super.setUp()
        scheduler = NonJSRuleScheduler()
        bookSource = BookSource(bookSourceName: "Test Source")
    }
    
    // MARK: - Positive Tests
    
    func testExtractHrefFromClassParentChildAnchor() throws {
        let html = """
        <div class="chapter">
            <a href="1.html">第1章</a>
        </div>
        <div class="chapter">
            <a href="2.html">第2章</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: ".chapter a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertEqual(result, ["1.html", "2.html"])
    }
    
    func testExtractSrcFromIdParentChildImage() throws {
        let html = """
        <div id="cover">
            <img src="cover.jpg" alt="Cover">
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "#cover img@src", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["cover.jpg"])
    }
    
    func testExtractTextFromTagClassParentChildSpan() throws {
        let html = """
        <div class="info">
            <span>作者名</span>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "div.info span@text", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["作者名"])
    }
    
    func testExtractHrefFromTagParentChildAnchor() throws {
        let html = """
        <li>
            <a href="/chapter/1.html">第1章</a>
        </li>
        <li>
            <a href="/chapter/2.html">第2章</a>
        </li>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "li a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertEqual(result, ["/chapter/1.html", "/chapter/2.html"])
    }
    
    // MARK: - Attribute Extraction Strict Tests
    
    func testAttributeExtractionStrictStillDoesNotTraverse() throws {
        let html = """
        <div class="chapter">
            <a href="1.html">第1章</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // .chapter@href should return empty because div.chapter doesn't have href attribute
        let result1 = try scheduler.evaluate(rule: ".chapter@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result1.isEmpty)
        
        // a@href should return 1.html
        let result2 = try scheduler.evaluate(rule: "a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertEqual(result2, ["1.html"])
    }
    
    // MARK: - V2 Compatibility Tests
    
    func testV2SimpleSelectorsStillWork() throws {
        let html = """
        <div class="content">
            <p>Chapter 1</p>
            <p>Chapter 2</p>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: ".content", data: data, flow: .content, source: bookSource)
        XCTAssertEqual(result, ["Chapter 1\n    Chapter 2"])
    }
    
    func testV2IdSelectorStillWorks() throws {
        let html = """
        <div id="content">
            <p>Chapter 1</p>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "#content", data: data, flow: .content, source: bookSource)
        XCTAssertEqual(result, ["Chapter 1"])
    }
    
    func testV2TagSelectorStillWorks() throws {
        let html = """
        <p>Line 1</p>
        <p>Line 2</p>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "p", data: data, flow: .content, source: bookSource)
        XCTAssertEqual(result, ["Line 1", "Line 2"])
    }
    
    // MARK: - Negative Tests - Multi-level Descendant
    
    func testRejectMultiLevelDescendant() throws {
        let html = """
        <div class="item">
            <a href="1.html">
                <span>第1章</span>
            </a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // .item a span@text should fail because it has multiple descendant levels
        // Actually this will return empty because the selector won't match
        let result = try scheduler.evaluate(rule: ".item a span@text", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Negative Tests - Child Selector
    
    func testRejectChildSelector() throws {
        let html = """
        <div>
            <a href="1.html">第1章</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // div > a@href should fail because > is not supported
        let result = try scheduler.evaluate(rule: "div > a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Negative Tests - Attribute Selector
    
    func testRejectAttributeSelector() throws {
        let html = """
        <a href="1.html">第1章</a>
        """
        let data = html.data(using: .utf8)!  
        // a[href]@href should fail because [href] syntax is not supported
        let result = try scheduler.evaluate(rule: "a[href]@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Negative Tests - Pseudo Selector
    
    func testRejectPseudoSelector() throws {
        let html = """
        <a href="1.html">Link 1</a>
        <a href="2.html">Link 2</a>
        """
        let data = html.data(using: .utf8)!  
        // a:eq(0)@href should fail because :eq is not supported
        let result = try scheduler.evaluate(rule: "a:eq(0)@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Negative Tests - Index Selector
    
    func testRejectIndexSelector() throws {
        let html = """
        <a href="1.html">Link 1</a>
        <a href="2.html">Link 2</a>
        """
        let data = html.data(using: .utf8)!  
        // a.0@href should fail because index syntax is not supported
        let result = try scheduler.evaluate(rule: "a.0@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Negative Tests - Unsupported Attribute
    
    func testRejectUnsupportedAttribute() throws {
        let html = """
        <a href="1.html" onclick="alert('test')">Link</a>
        """
        let data = html.data(using: .utf8)!  
        // a@onclick should fail because onclick is not in the whitelist
        XCTAssertThrowsError(try scheduler.evaluate(rule: "a@onclick", data: data, flow: .toc, source: bookSource))
    }
    
    // MARK: - Negative Tests - JS Rule
    
    func testRejectJSRule() throws {
        let html = """
        <div class="content">Test</div>
        """
        let data = html.data(using: .utf8)!  
        // @js: should fail
        XCTAssertThrowsError(try scheduler.evaluate(rule: "@js:", data: data, flow: .toc, source: bookSource))
    }
}