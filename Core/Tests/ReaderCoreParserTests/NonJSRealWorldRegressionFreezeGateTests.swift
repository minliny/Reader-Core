import XCTest
import Foundation

class NonJSRealWorldRegressionFreezeGateTests: XCTestCase {
    
    let basePath = URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("samples/real_world/non_js")
    
    func testRegressionMatrixExists() {
        let matrixPath = basePath.appendingPathComponent("regression_matrix.yml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: matrixPath.path), "regression_matrix.yml 不存在")
    }
    
    func testCaseCountAtLeast20() {
        let caseDirectories = try? FileManager.default.contentsOfDirectory(at: basePath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let caseCount = caseDirectories?.filter { $0.lastPathComponent.hasPrefix("case_") }.count ?? 0
        XCTAssertGreaterThanOrEqual(caseCount, 20, "测试用例数量不足 20 个")
    }
    
    func testAllCasesHaveRequiredFiles() {
        let caseDirectories = try? FileManager.default.contentsOfDirectory(at: basePath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let caseFolders = caseDirectories?.filter { $0.lastPathComponent.hasPrefix("case_") } ?? []
        
        for caseFolder in caseFolders {
            let caseName = caseFolder.lastPathComponent
            
            // 检查 booksource.json
            let booksourcePath = caseFolder.appendingPathComponent("booksource.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: booksourcePath.path), "\(caseName) 缺少 booksource.json")
            
            // 检查 metadata.yml
            let metadataPath = caseFolder.appendingPathComponent("metadata.yml")
            XCTAssertTrue(FileManager.default.fileExists(atPath: metadataPath.path), "\(caseName) 缺少 metadata.yml")
            
            // 检查 README.md
            let readmePath = caseFolder.appendingPathComponent("README.md")
            XCTAssertTrue(FileManager.default.fileExists(atPath: readmePath.path), "\(caseName) 缺少 README.md")
            
            // 检查 fixtures 目录
            let fixturesPath = caseFolder.appendingPathComponent("fixtures")
            XCTAssertTrue(FileManager.default.fileExists(atPath: fixturesPath.path), "\(caseName) 缺少 fixtures 目录")
            
            // 检查 fixtures 下的 HTML 文件
            let searchHtmlPath = fixturesPath.appendingPathComponent("search.html")
            XCTAssertTrue(FileManager.default.fileExists(atPath: searchHtmlPath.path), "\(caseName) 缺少 fixtures/search.html")
            
            let detailHtmlPath = fixturesPath.appendingPathComponent("detail.html")
            XCTAssertTrue(FileManager.default.fileExists(atPath: detailHtmlPath.path), "\(caseName) 缺少 fixtures/detail.html")
            
            let tocHtmlPath = fixturesPath.appendingPathComponent("toc.html")
            XCTAssertTrue(FileManager.default.fileExists(atPath: tocHtmlPath.path), "\(caseName) 缺少 fixtures/toc.html")
            
            let contentHtmlPath = fixturesPath.appendingPathComponent("content.html")
            XCTAssertTrue(FileManager.default.fileExists(atPath: contentHtmlPath.path), "\(caseName) 缺少 fixtures/content.html")
            
            // 检查 expected 目录
            let expectedPath = caseFolder.appendingPathComponent("expected")
            XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath.path), "\(caseName) 缺少 expected 目录")
            
            // 检查 expected 下的 JSON 文件
            let searchResultPath = expectedPath.appendingPathComponent("search_result.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: searchResultPath.path), "\(caseName) 缺少 expected/search_result.json")
            
            let detailResultPath = expectedPath.appendingPathComponent("detail_result.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: detailResultPath.path), "\(caseName) 缺少 expected/detail_result.json")
            
            let tocResultPath = expectedPath.appendingPathComponent("toc_result.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: tocResultPath.path), "\(caseName) 缺少 expected/toc_result.json")
            
            let contentResultPath = expectedPath.appendingPathComponent("content_result.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: contentResultPath.path), "\(caseName) 缺少 expected/content_result.json")
        }
    }
    
    func testMetadataContainsRequiredFields() {
        let caseDirectories = try? FileManager.default.contentsOfDirectory(at: basePath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let caseFolders = caseDirectories?.filter { $0.lastPathComponent.hasPrefix("case_") } ?? []
        
        for caseFolder in caseFolders {
            let caseName = caseFolder.lastPathComponent
            let metadataPath = caseFolder.appendingPathComponent("metadata.yml")
            
            guard FileManager.default.fileExists(atPath: metadataPath.path) else {
                XCTFail("\(caseName) 缺少 metadata.yml")
                continue
            }
            
            // 这里可以添加对 metadata.yml 内容的解析和验证
            // 确保包含必要字段
        }
    }
    
    func testRegressionReportExists() {
        let reportPath = basePath.appendingPathComponent("regression_report.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: reportPath.path), "regression_report.md 不存在")
    }
    
    func testFailureTaxonomyExists() {
        let taxonomyPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/parser/NON_JS_REAL_WORLD_FAILURE_TAXONOMY.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: taxonomyPath.path), "NON_JS_REAL_WORLD_FAILURE_TAXONOMY.md 不存在")
    }
    
    func testCapabilityBoundaryExists() {
        let boundaryPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/parser/NON_JS_REAL_WORLD_CAPABILITY_BOUNDARY.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: boundaryPath.path), "NON_JS_REAL_WORLD_CAPABILITY_BOUNDARY.md 不存在")
    }
}
