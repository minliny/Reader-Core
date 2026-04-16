// SearchDemoView.swift
// Minimal SwiftUI view that displays the three-phase demo loop result.
// No product UI — integration loop verification only.

import SwiftUI
import ReaderCoreModels

// MARK: - SearchDemoView

public struct SearchDemoView: View {

    @ObservedObject var vm: SearchDemoViewModel

    public init(vm: SearchDemoViewModel) {
        self.vm = vm
    }

    public var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                phaseHeader
                Divider()
                logSection
                Divider()
                resultsSection
            }
            .navigationTitle("Core Demo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Run") {
                        Task { await vm.runDemo() }
                    }
                    .disabled(vm.phase == .running(step: "search")
                           || vm.phase == .running(step: "toc")
                           || vm.phase == .running(step: "content"))
                }
            }
        }
    }

    // MARK: Sub-views

    @ViewBuilder
    private var phaseHeader: some View {
        HStack {
            Image(systemName: phaseIcon)
                .foregroundColor(phaseColor)
            Text(phaseLabel)
                .font(.subheadline)
                .foregroundColor(phaseColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var logSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Log").font(.caption).foregroundColor(.secondary).padding(.horizontal)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(vm.log.indices, id: \.self) { i in
                        Text(vm.log[i])
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 140)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var resultsSection: some View {
        List {
            if !vm.searchResults.isEmpty {
                Section("Search Results (\(vm.searchResults.count))") {
                    ForEach(vm.searchResults, id: \.detailURL) { item in
                        VStack(alignment: .leading) {
                            Text(item.title).font(.subheadline)
                            if let author = item.author {
                                Text(author).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            if !vm.tocItems.isEmpty {
                Section("TOC (\(vm.tocItems.count))") {
                    ForEach(vm.tocItems.prefix(5), id: \.chapterURL) { ch in
                        Text(ch.title).font(.caption)
                    }
                }
            }
            if let page = vm.contentPage {
                Section("Content") {
                    Text(page.content.prefix(200) + "…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: Phase helpers

    private var phaseIcon: String {
        switch vm.phase {
        case .idle:            return "circle"
        case .running:         return "arrow.triangle.2.circlepath"
        case .done:            return "checkmark.circle.fill"
        case .failed:          return "xmark.circle.fill"
        }
    }

    private var phaseColor: Color {
        switch vm.phase {
        case .idle:            return .secondary
        case .running:         return .accentColor
        case .done:            return .green
        case .failed:          return .red
        }
    }

    private var phaseLabel: String {
        switch vm.phase {
        case .idle:                    return "Idle — tap Run to start"
        case .running(let step):       return "Running: \(step)…"
        case .done:                    return "Core connected"
        case .failed(let msg):         return "Failed: \(msg)"
        }
    }
}
