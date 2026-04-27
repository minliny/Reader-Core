import XCTest
import ReaderCoreParser
import ReaderCoreModels

final class TextFilterMinimalTests: XCTestCase {
    
    private var scheduler: NonJSRuleScheduler!
    private var bookSource: BookSource!
    
    override func setUp() {
        super.setUp()
        scheduler = NonJSRuleScheduler()
        bookSource = BookSource(bookSourceName: "Test Source")
    }
    
    // MARK: - Positive Tests
    
    func testExtractHrefFromText() throws {
        let html = """
        <div>
            <a href="toc.html">目录</a>
            <a href="index.html">首页</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "text.目录@href", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["toc.html"])
    }
    
    func testExtractHrefFromChineseText() throws {
        let html = """
        <div>
            <a href="full.html">全集目录</a>
            <a href="chapter1.html">第一章</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "text.全集目录@href", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["full.html"])
    }
    
    func testExtractTextFromTextFilter() throws {
        let html = """
        <div>
            <p>作者：张三</p>
            <p>出版社：人民文学出版社</p>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "text.作者", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["作者：张三"])
    }
    
    func testParentScopedTextFilter() throws {
        let html = """
        <div class="nav">
            <a href="prev.html">上一章</a>
            <a href="next.html">下一章</a>
        </div>
        <div class="footer">
            <a href="index.html">首页</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: ".nav text.下一章@href", data: data, flow: .content, source: bookSource)
        XCTAssertEqual(result, ["next.html"])
    }
    
    func testTextFilterWithoutAttr() throws {
        let html = """
        <div>
            <p>简介：这是一本好书</p>
            <p>目录：第一章、第二章</p>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: "text.简介", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["简介：这是一本好书"])
    }
    
    // MARK: - Negative Tests
    
    func testRejectRegexText() throws {
        let html = """
        <div>
            <a href="toc.html">目录1</a>
            <a href="toc2.html">目录2</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // text.目录.* should not match due to regex
        let result = try scheduler.evaluate(rule: "text.目录.*", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectMultiText() throws {
        let html = """
        <div>
            <a href="test.html">目录 作者</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // text.目录 text.作者 should fail
        let result = try scheduler.evaluate(rule: "text.目录 text.作者", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectPseudo() throws {
        let html = """
        <div>
            <a href="toc.html">目录</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // text.目录:eq(0) should fail
        let result = try scheduler.evaluate(rule: "text.目录:eq(0)", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectIndex() throws {
        let html = """
        <div>
            <a href="toc.html">目录</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // text.目录.0 should fail
        let result = try scheduler.evaluate(rule: "text.目录.0", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testRejectJS() throws {
        let html = """
        <div>
            <a href="toc.html">目录</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // @js: should fail
        XCTAssertThrowsError(try scheduler.evaluate(rule: "@js:", data: data, flow: .bookInfo, source: bookSource))
    }
    
    func testNoFallbackToDescendant() throws {
        let html = """
        <div class="container">
            <span>目录</span>
            <a href="toc.html">点击查看</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // text.目录 should only match the span, not the a tag
        let result = try scheduler.evaluate(rule: "text.目录@href", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testNestedTagTextFilter() throws {
        let html = """
        <a href="list.html"><span>目录</span></a>
        """
        let data = html.data(using: .utf8)!  
        // text.目录 should match the span, but get href from the parent a tag
        let result = try scheduler.evaluate(rule: "text.目录@href", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["list.html"])
    }
    
    func testSiblingTagTextFilter() throws {
        let html = """
        <span>目录</span><a href="x">点击查看</a>
        """
        let data = html.data(using: .utf8)!  
        // text.目录 should only match the span, not the sibling a tag
        let result = try scheduler.evaluate(rule: "text.目录@href", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testMinimalClickableAncestorTextFilter() throws {
        let html = """
        <a href="x"><span>目录</span></a>
        """
        let data = html.data(using: .utf8)!  
        // text.目录 should match the span and get href from the minimal clickable ancestor (a tag)
        let result = try scheduler.evaluate(rule: "text.目录@href", data: data, flow: .bookInfo, source: bookSource)
        XCTAssertEqual(result, ["x"])
    }
    
    // MARK: - Compatibility Tests
    
    func testV2SelectorsStillWork() throws {
        let html = """
        <div class="content">
            <p>Chapter 1</p>
        </div>
        """
        let data = html.data(using: .utf8)!  
        let result = try scheduler.evaluate(rule: ".content", data: data, flow: .content, source: bookSource)
        XCTAssertEqual(result, ["Chapter 1"])
    }
    
    func testAttributeExtractionStillStrict() throws {
        let html = """
        <div class="chapter">
            <a href="1.html">第1章</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // .chapter@href should return empty
        let result = try scheduler.evaluate(rule: ".chapter@href", data: data, flow: .toc, source: bookSource)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testDescendantSelectorStillWorks() throws {
        let html = """
        <div class="chapter">
            <a href="1.html">第1章</a>
        </div>
        """
        let data = html.data(using: .utf8)!  
        // .chapter a@href should return 1.html
        let result = try scheduler.evaluate(rule: ".chapter a@href", data: data, flow: .toc, source: bookSource)
        XCTAssertEqual(result, ["1.html"])
    }
}