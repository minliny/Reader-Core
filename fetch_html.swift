#!/usr/bin/env swift
// fetch_html.swift
// Minimal script to fetch and save HTML for analysis
import Foundation
import ReaderPlatformAdapters

@main
struct FetchHTML {
    static func main() async {
        let httpClient = MinimalHTTPAdapter()
        let url = "https://www.tianyabooks.com"
        
        print("Fetching: \(url)")
        do {
            let request = HTTPRequest(url: url, method: "GET")
            let response = try await httpClient.send(request)
            print("Status: \(response.statusCode)")
            
            if let html = String(data: response.data, encoding: .utf8) {
                let outputPath = "tianyabooks_home.html"
                try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("Saved to: \(outputPath)")
                
                // Check for leftbox class
                if html.contains("leftbox") {
                    print("Found 'leftbox' in HTML")
                } else {
                    print("'leftbox' NOT found in HTML")
                }
            } else {
                print("Failed to parse HTML")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}