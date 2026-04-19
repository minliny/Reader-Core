// LinuxSmokeRunner/linux_smoke_main.swift
// Entry point for Linux non-JS smoke test.
// @main on a dedicated file — avoids Linux Swift's
// "top-level code + @main in same module" conflict.
// Run: swift run --package-path Core --configuration release LinuxSmokeRunner
import Foundation
import ReaderCoreModels
import ReaderCoreParser

@main
struct Main {
    static func main() {
        let repoRoot = FileManager.default.currentDirectoryPath
        var runner = SmokeRunner(repoRoot: repoRoot)
        let passed = runner.runAll()
        exit(passed ? 0 : 1)
    }
}
