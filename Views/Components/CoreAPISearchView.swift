//
//  CoreAPISearchView.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import SwiftUI

struct CoreAPISearchView: View {
    @Environment(\.dismiss) var dismiss
    @State private var queryText: String = ""
    @State private var limit: Int = 10
    @State private var searchResults: [SearchResultItem] = []
    @State private var searchErrorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var addingPapers: Set<String> = [] // Track which papers are being added
    @State private var selectedPaper: SearchResultItem? = nil // Track selected paper
    @State private var availableCollections: [Collection] = [] // All collections for picker
    @State private var isLoadingCollections: Bool = false
    @State private var searchHistory: [SearchHistoryItem] = [] // Search history with results
    @State private var showSearchHistory: Bool = false // Toggle for history view
    @State private var showNewCollectionForm: Bool = false // Show inline collection form

    // MARK: - Search History Data Structure
    struct SearchHistoryItem: Codable, Identifiable {
        let id: UUID
        let query: String
        let timestamp: Date
        let resultCount: Int
        let results: [SearchResultItem]
        
        // Custom initializer for creating new items
        init(query: String, timestamp: Date, resultCount: Int, results: [SearchResultItem]) {
            self.id = UUID()
            self.query = query
            self.timestamp = timestamp
            self.resultCount = resultCount
            self.results = results
        }
        
        var timeAgo: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: timestamp, relativeTo: Date())
        }
    }

    @Binding var selectedCollection: Collection? // This contains the papers already in it
    let onAddPaperToCollection: (Int, SearchResultItem) -> Void

    // MARK: - New State for Locally Managed 'Already Added'
    @State private var papersInCurrentCollectionIds: Set<String> = []

    var body: some View {
        NavigationView {
            List {
                // ADDED: Collection Selection Section
                Section {
                    if isLoadingCollections {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading collections...")
                                .foregroundColor(.secondary)
                        }
                    } else if availableCollections.isEmpty {
                        Text("No collections available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Picker("Target Collection", selection: Binding(
                            get: { selectedCollection?.id ?? -1 },
                            set: { newId in
                                if newId == -2 {
                                    // Special value for "Create New Collection"
                                    showNewCollectionForm = true
                                } else if let collection = availableCollections.first(where: { $0.id == newId }) {
                                    selectedCollection = collection
                                }
                            }
                        )) {
                            Text("Select a collection...")
                                .tag(-1)
                            
                            Text("➕ Create New Collection")
                                .tag(-2)
                            
                            ForEach(availableCollections) { collection in
                                VStack(alignment: .leading) {
                                    Text(collection.title)
                                        .font(.headline)
                                    Text("\(collection.papersCount) papers")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(collection.id)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        // Inline New Collection Form
                        if showNewCollectionForm {
                            InlineNewCollectionForm(
                                onSave: { title, owner, description in
                                    createNewCollection(title: title, owner: owner, description: description)
                                },
                                onCancel: {
                                    showNewCollectionForm = false
                                }
                            )
                        }
                        
                        // Show selected collection details
                        if let selected = selectedCollection {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(selected.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(selected.papersCount) papers")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !selected.description.isEmpty {
                                    Text(selected.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Text("Owner: \(selected.owner ?? "Unknown")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                } header: {
                    Text("Target Collection")
                } footer: {
                    if selectedCollection == nil {
                        Text("Please select a collection to add papers to")
                            .foregroundColor(.orange)
                    }
                }
                
                // Search form section
                Section {
                    HStack {
                        TextField("Search Query", text: $queryText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        // History button
                        Button(action: {
                            showSearchHistory.toggle()
                        }) {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    // Search History dropdown
                    if showSearchHistory && !searchHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Search History")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Clear All") {
                                    clearSearchHistory()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            
                            ForEach(searchHistory.prefix(5)) { historyItem in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(historyItem.query)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            
                                            HStack {
                                                Text("\(historyItem.resultCount) results")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                
                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                
                                                Text(historyItem.timeAgo)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 8) {
                                            // Load results button
                                            Button("Load") {
                                                loadHistoryResults(historyItem)
                                            }
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .cornerRadius(6)
                                            
                                            // Reuse query button
                                            Button("Search") {
                                                queryText = historyItem.query
                                                showSearchHistory = false
                                                performSearch()
                                            }
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(6)
                                        }
                                    }
                                    
                                    // Show first few result titles
                                    if !historyItem.results.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            ForEach(historyItem.results.prefix(2)) { result in
                                                Text("• \(result.title)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            if historyItem.results.count > 2 {
                                                Text("... and \(historyItem.results.count - 2) more")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .italic()
                                            }
                                        }
                                        .padding(.leading, 8)
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Text("Limit:")
                        Spacer()
                        Stepper("\(limit)", value: $limit, in: 1...50)
                    }
                    
                    Button {
                        performSearch()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Searching..." : "Search Core API")
                        }
                    }
                    .disabled(queryText.isEmpty || isLoading)
                    .buttonStyle(.borderedProminent)
                } header: {
                    Text("Core API Search Parameters")
                }
                
                // Error message section
                if !searchErrorMessage.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(searchErrorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Button("Clear Error") {
                                searchErrorMessage = ""
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Results section
                if isLoading {
                    Section("Searching...") {
                        HStack {
                            ProgressView()
                            Text("Searching CORE API...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)
                    }
                } else if searchResults.isEmpty && !queryText.isEmpty && searchErrorMessage.isEmpty {
                    Section {
                        Text("No results found for '\(queryText)'")
                            .foregroundColor(.gray)
                            .italic()
                    }
                } else if !searchResults.isEmpty {
                    Section("Search Results (\(searchResults.count))") {
                        ForEach(searchResults) { item in
                            PaperSearchResultRow(
                                paper: item,
                                isSelected: selectedPaper?.id == item.id,
                                isAlreadyInCollection: papersInCurrentCollectionIds.contains(item.id),
                                isAddingToCollection: addingPapers.contains(item.id),
                                selectedCollectionTitle: selectedCollection?.title ?? "Collection",
                                onTap: {
                                    selectedPaper = selectedPaper?.id == item.id ? nil : item
                                },
                                onAddToCollection: {
                                    addPaperToCollection(item)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Search Core API")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // Show selected paper count
                if let selectedPaper = selectedPaper {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Deselect") {
                            self.selectedPaper = nil
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                loadAvailableCollections()
                setupPapersInCurrentCollectionIds()
                loadSearchHistory()
            }
            .onChange(of: selectedCollection) {
                setupPapersInCurrentCollectionIds()
            }
        }
    }

    // MARK: - Search History Functions
    private func loadSearchHistory() {
        // Load search history from UserDefaults
        if let savedData = UserDefaults.standard.data(forKey: "CoreAPISearchHistoryWithResults"),
           let decodedHistory = try? JSONDecoder().decode([SearchHistoryItem].self, from: savedData) {
            searchHistory = decodedHistory
        }
    }
    
    private func addSearchResultsToHistory(query: String, results: [SearchResultItem]) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't add empty queries
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove existing entry with same query (to avoid duplicates and update with new results)
        searchHistory.removeAll { $0.query.lowercased() == trimmedQuery.lowercased() }
        
        // Create new history item
        let historyItem = SearchHistoryItem(
            query: trimmedQuery,
            timestamp: Date(),
            resultCount: results.count,
            results: results
        )
        
        // Add to beginning of array
        searchHistory.insert(historyItem, at: 0)
        
        // Keep only last 10 searches
        if searchHistory.count > 10 {
            searchHistory.removeLast()
        }
        
        // Save to UserDefaults
        if let encodedData = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(encodedData, forKey: "CoreAPISearchHistoryWithResults")
        }
    }
    
    private func loadHistoryResults(_ historyItem: SearchHistoryItem) {
        searchResults = historyItem.results
        queryText = historyItem.query
        showSearchHistory = false
    }
    
    private func clearSearchHistory() {
        searchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "CoreAPISearchHistoryWithResults")
        showSearchHistory = false
    }

    private func performSearch() {
        isLoading = true
        searchErrorMessage = ""
        selectedPaper = nil // Clear selection on new search
        showSearchHistory = false // Hide history when searching
        
        Task {
            do {
                searchResults = try await APIService.shared.searchCoreAPI(query: queryText, limit: limit)
                // For testing with mock data, use this instead:
                // searchResults = try await APIService.shared.searchCoreAPIMock(query: queryText, limit: limit)
                
                // Save search results to history
                await MainActor.run {
                    addSearchResultsToHistory(query: queryText, results: searchResults)
                }
            } catch {
                searchErrorMessage = "Failed to search Core API: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func addPaperToCollection(_ item: SearchResultItem) {
        guard let collectionId = selectedCollection?.id else {
            searchErrorMessage = "No collection selected"
            return
        }
        
        addingPapers.insert(item.id)

        Task {
            do {
                onAddPaperToCollection(collectionId, item)

                // Add the paper's ID to the local set to immediately update UI
                papersInCurrentCollectionIds.insert(item.id)

                // Optional: A small delay to show the progress indicator
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

                addingPapers.remove(item.id)

            } catch {
                addingPapers.remove(item.id)
                searchErrorMessage = "Failed to add paper: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Load Collections for Picker
    private func loadAvailableCollections() {
        isLoadingCollections = true
        
        Task {
            do {
                let collections = try await APIService.shared.loadCollections()
                
                await MainActor.run {
                    availableCollections = collections
                    
                    // If current selectedCollection is nil, but we had one passed in originally,
                    // try to find it in the loaded collections
                    if let currentSelected = selectedCollection {
                        // Update selectedCollection with fresh data
                        if let updatedCollection = collections.first(where: { $0.id == currentSelected.id }) {
                            selectedCollection = updatedCollection
                        }
                    }
                    
                    isLoadingCollections = false
                }
            } catch {
                await MainActor.run {
                    searchErrorMessage = "Failed to load collections: \(error.localizedDescription)"
                    isLoadingCollections = false
                }
            }
        }
    }

    // MARK: - Helper Function
    private func setupPapersInCurrentCollectionIds() {
        if let currentPapers = selectedCollection?.papers {
            // Create a set of core_ids from papers already in the collection
            var existingCoreIds = Set<String>()
            
            for paper in currentPapers {
                // If paper has a core_id, use that for comparison
                if let coreId = paper.coreId, !coreId.isEmpty {
                    existingCoreIds.insert(coreId)
                }
                // Also add the paper title as fallback for manual papers
                existingCoreIds.insert(paper.title)
            }
            
            papersInCurrentCollectionIds = existingCoreIds
        } else {
            papersInCurrentCollectionIds = []
        }
    }
    
    // MARK: - Create New Collection
    private func createNewCollection(title: String, owner: String, description: String) {
        Task {
            do {
                try await APIService.shared.createCollection(title: title, owner: owner, description: description)
                
                // Reload collections and select the new one
                await MainActor.run {
                    showNewCollectionForm = false
                    loadAvailableCollections()
                }
                
                // Wait a bit for the collection to be created and then try to select it
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    // Find and select the newly created collection
                    if let newCollection = availableCollections.first(where: { $0.title == title }) {
                        selectedCollection = newCollection
                    }
                }
                
            } catch {
                await MainActor.run {
                    searchErrorMessage = "Failed to create collection: \(error.localizedDescription)"
                    showNewCollectionForm = false
                }
            }
        }
    }
}

// MARK: - Inline New Collection Form Component
struct InlineNewCollectionForm: View {
    let onSave: (String, String, String) -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var owner: String = ""
    @State private var description: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create New Collection")
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                TextField("Collection Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Owner (Optional)", text: $owner)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Description (Optional)", text: $description, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create") {
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedOwner = owner.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    onSave(trimmedTitle, trimmedOwner, trimmedDescription)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Paper Search Result Row Component
struct PaperSearchResultRow: View {
    let paper: SearchResultItem
    let isSelected: Bool
    let isAlreadyInCollection: Bool
    let isAddingToCollection: Bool
    let selectedCollectionTitle: String
    let onTap: () -> Void
    let onAddToCollection: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with selection indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(paper.title)
                        .font(.headline)
                        .lineLimit(isSelected ? nil : 2)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                    
                    // Show CORE ID badge
                    if let coreId = paper.coreId, !coreId.isEmpty {
                        Text("CORE ID: \(coreId)")
                            .font(.caption2)
                            .foregroundColor(.blue.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            
            // Expandable content
            if isSelected {
                VStack(alignment: .leading, spacing: 8) {
                    // Abstract
                    if let abstract = paper.abstract, !abstract.isEmpty {
                        Text("Abstract:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(abstract)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Authors
                    if let authors = paper.authors, !authors.isEmpty {
                        Text("Authors:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(authors)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Publication Date
                    if let pubDate = paper.publicationDate, !pubDate.isEmpty {
                        Text("Published:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(pubDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Source
                    Text("Source:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(paper.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Links
                    HStack(spacing: 12) {
                        // Download PDF link
                        if let downloadUrlString = paper.downloadUrl, !downloadUrlString.isEmpty, let downloadUrl = URL(string: downloadUrlString) {
                            Link(destination: downloadUrl) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.doc")
                                    Text("Download PDF")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.green)
                        }
                        
                        // Regular URL link
                        if let urlString = paper.url, !urlString.isEmpty, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                    Text("View Paper")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if (paper.url?.isEmpty ?? true) && (paper.downloadUrl?.isEmpty ?? true) {
                            Text("No links available")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Add to collection button
            HStack {
                if isAlreadyInCollection {
                    Text("✅ Already in this collection")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Button {
                        onAddToCollection()
                    } label: {
                        HStack {
                            if isAddingToCollection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Add to \(selectedCollectionTitle)")
                        }
                    }
                    .disabled(isAddingToCollection)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        }
    }
}
