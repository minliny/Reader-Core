import XCTest
import ReaderCoreParser
import ReaderCoreModels

final class AttributeExtractionMinimalTests: XCTestCase {
    
    private var scheduler: NonJSRuleScheduler!
    private var bookSource: BookSource!
    
    override func setUp() {
        super.setUp()
        scheduler = NonJSRuleScheduler()
        bookSource = BookSource(bookSourceName: "Test Source")
    }
    
    // MARK: - Positive Tests
    
    func testExtractHrefFromClassSelector() throws {
        let html = """
        <a class="chapter" href="https://example.com/chapter1">第一章</a>
        <a class="chapter" href="https://example.com/chapter2">第二章</a>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: ".chapter@href", data: data, flow: .toc, source: bookSource)
        XCTAssertEqual(result, ["https://example.com/chapter1", "https://example.com/chapter2"])
    }
    
    func testExtractSrcFromIdSelector() throws {
        let html = """
        <img id="cover" src="https://example.com/cover.jpg" alt="Cover">
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "#cover@src", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["https://example.com/cover.jpg"])
    }
    
    func testExtractContentFromTagClassSelector() throws {
        let html = """
        <meta class="book" content="https://example.com/book1">
        <meta name="description" content="Test book">
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "meta.book@content", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["https://example.com/book1"])
    }
    
    func testExtractHrefFromTagSelector() throws {
        let html = """
        <a href="https://example.com/link1">Link 1</a>
        <a href="https://example.com/link2">Link 2</a>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertEqual(result, ["https://example.com/link1", "https://example.com/link2"])
    }
    
    func testExtractHrefFromTagClassSelector() throws {
        let html = """
        <a class="chapter" href="https://example.com/chapter1">第一章</a>
        <a class="chapter" href="https://example.com/chapter2">第二章</a>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "a.chapter@href", data: data, flow: .toc, source: bookSource)
        XCTAssertEqual(result, ["https://example.com/chapter1", "https://example.com/chapter2"])
    }
    
    // MARK: - Negative Tests
    
    func testRejectDescendantSelectorWithAttribute() throws {
        let html = """
        <div class="item">
            <a href="https://example.com/link">Link</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: ".item a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectChildSelectorWithAttribute() throws {
        let html = """
        <div>
            <a href="https://example.com/link">Link</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "div > a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectAttributeSelectorSyntax() throws {
        let html = """
        <a href="https://example.com/link">Link</a>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "a[href]@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectPseudoSelectorSyntax() throws {
        let html = """
        <a href="https://example.com/link1">Link 1</a>
        <a href="https://example.com/link2">Link 2</a>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "a:eq(0)@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectUnsupportedAttribute() throws {
        let html = """
        <a href="https://example.com/link" onclick="alert('test')">Link</a>
        """
        let data = html.data(using: .utf8)!  
        XCTAssertThrowsError(try scheduler.evaluate(rule: "a@onclick", data: data, flow: .toc, source: bookSource))
    }
    
    // MARK: - V2 Compatibility Tests
    
    func testV2SelectorsStillWork() throws {
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
    
    func testV2TagClassSelectorStillWorks() throws {
        let html = """
        <p class="text">Line 1</p>
        <p class="text">Line 2</p>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "p.text", data: data, flow: .content, source: bookSource)
        XCTAssertEqual(result, ["Line 1", "Line 2"])
    }
    
    // MARK: - Selector@attr Semantics Tests
    
    func testSelectorAttrDoesNotTraverse() throws {
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
}
