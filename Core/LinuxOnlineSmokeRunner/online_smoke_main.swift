// LinuxOnlineSmokeRunner/online_smoke_main.swift
import Foundation

@main
struct Main {
    static func main() async {
        let repoRoot = "."
        let bookSourcePath = "samples/booksources/auto/auto_09966b3b.json"

        let runner = OnlineSmokeRunner(repoRoot: repoRoot)
        let passed = await runner.runOnline(bookSourcePath: bookSourcePath)
        exit(passed ? 0 : 1)
    }
}