//
//  ContentView.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection? = nil
    @State private var showAddForm = false
    @State private var showSearchSheet = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed header section (not scrollable)
                VStack {
                    Text("Research Collections")
                        .font(.largeTitle)
                        .padding()

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    HStack {
                        Button("➕ Create New Collection") {
                            showAddForm = true
                        }
                        .padding()

                        Button("🔍 Search Core API") {
                            showSearchSheet = true
                        }
                        .padding()
                    }
                }
                .background(Color(.systemBackground))
                
                // Scrollable collections section
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(collections) { collection in
                            CollectionView(
                                collection: collection,
                                isSelected: selectedCollection?.id == collection.id,
                                selectedCollection: selectedCollection,
                                onSelect: {
                                    selectCollection(collection)
                                },
                                onClose: {
                                    selectedCollection = nil
                                },
                                onDelete: { deleteCollection(collection.id) },
                                onAddPaper: addPaper,
                                onDeletePaper: deletePaper
                            )
                            .id(collection.id)
                        }
                    }
                    .padding()
                }
            }
        }
        .task { loadCollections() }
        .sheet(isPresented: $showAddForm) {
            NewCollectionForm { title, owner, description in
                createCollection(title: title, owner: owner, description: description)
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            CoreAPISearchView(
                selectedCollection: $selectedCollection,
                onAddPaperToCollection: addPaper
            )
        }
        // ADDED: Refresh collections when returning from search sheet
        .onChange(of: showSearchSheet) {
            if !showSearchSheet {
                // Search sheet was dismissed, refresh collections
                print("🔄 [CONTENT VIEW] Search sheet dismissed, refreshing collections...")
                
                // Add a small delay to ensure backend has processed any changes
                Task {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    await MainActor.run {
                        loadCollections()
                    }
                }
            }
        }
    }

    // MARK: - Actions
    func loadCollections() {
        print("🔄 [CONTENT VIEW] === LOADING COLLECTIONS ===")
        print("🔄 [CONTENT VIEW] Current collections count: \(collections.count)")
        
        Task {
            do {
                let newCollections = try await APIService.shared.loadCollections()
                
                await MainActor.run {
                    print("✅ [CONTENT VIEW] === COLLECTIONS LOADED ===")
                    print("✅ [CONTENT VIEW] New collections count: \(newCollections.count)")
                    
                    // Log paper counts for each collection
                    for collection in newCollections {
                        let oldCount = collections.first(where: { $0.id == collection.id })?.papersCount ?? 0
                        let newCount = collection.papersCount
                        
                        if oldCount != newCount {
                            print("📊 [CONTENT VIEW] Collection '\(collection.title)' count changed: \(oldCount) → \(newCount)")
                        } else {
                            print("📊 [CONTENT VIEW] Collection '\(collection.title)' count unchanged: \(newCount)")
                        }
                    }
                    
                    collections = newCollections
                    print("✅ [CONTENT VIEW] Collections state updated")
                }
            } catch {
                errorMessage = "Error loading collections: \(error.localizedDescription)"
                print("❌ [CONTENT VIEW] Error loading collections: \(error)")
            }
        }
    }

    func selectCollection(_ collection: Collection) {
        // Only open if not already selected, don't close on reselect
        if selectedCollection?.id == collection.id {
            return
        }

        Task {
            do {
                let papers = try await APIService.shared.fetchPapers(for: collection.id)

                var updatedCollection = collection
                updatedCollection.papers = papers
                selectedCollection = updatedCollection
            } catch {
                print("Error in selectCollection: \(error)")
                errorMessage = "Error loading papers: \(error.localizedDescription)"
            }
        }
    }

    func createCollection(title: String, owner: String, description: String) {
        Task {
            do {
                try await APIService.shared.createCollection(title: title, owner: owner, description: description)
                loadCollections() // Refresh the list
                showAddForm = false
            } catch {
                errorMessage = "Error creating collection: \(error.localizedDescription)"
            }
        }
    }

    func deleteCollection(_ id: Int) {
        Task {
            do {
                try await APIService.shared.deleteCollection(id: id)
                collections.removeAll { $0.id == id }
                if selectedCollection?.id == id { selectedCollection = nil }
            } catch {
                errorMessage = "Error deleting collection: \(error.localizedDescription)"
            }
        }
    }

    func addPaper(collectionId: Int, searchResult: SearchResultItem) {
        print("📝 [CONTENT VIEW] === ADD PAPER STARTED ===")
        print("📝 [CONTENT VIEW] Collection ID: \(collectionId)")
        print("📝 [CONTENT VIEW] Paper title: \(searchResult.title)")
        print("📝 [CONTENT VIEW] Paper core_id: \(searchResult.coreId ?? "nil")")
        
        Task {
            do {
                // Get current collection count before adding
                let currentCollection = collections.first(where: { $0.id == collectionId })
                let currentCount = currentCollection?.papersCount ?? 0
                print("📝 [CONTENT VIEW] Current paper count for collection: \(currentCount)")
                
                try await APIService.shared.addPaper(collectionId: collectionId, searchResult: searchResult)
                print("✅ [CONTENT VIEW] API call completed successfully")
                
                print("🔄 [CONTENT VIEW] Refreshing collections after adding paper...")
                // Add a small delay to ensure backend has processed the addition
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                
                await MainActor.run {
                    loadCollections()
                }
                
                // Wait for collections to load and then check the count
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                
                await MainActor.run {
                    let updatedCollection = collections.first(where: { $0.id == collectionId })
                    let updatedCount = updatedCollection?.papersCount ?? 0
                    print("📊 [CONTENT VIEW] Updated paper count: \(currentCount) → \(updatedCount)")
                    
                    if updatedCount > currentCount {
                        print("✅ [CONTENT VIEW] Paper count increased as expected!")
                    } else {
                        print("⚠️ [CONTENT VIEW] Paper count did not increase - backend might not be updating count")
                    }
                }
                
                // Reload the selected collection to show the new paper
                if let selected = selectedCollection,
                   let collection = collections.first(where: { $0.id == selected.id }) {
                    print("🔄 [CONTENT VIEW] Reloading selected collection papers...")
                    selectCollection(collection)
                }
            } catch {
                errorMessage = "Error adding paper: \(error.localizedDescription)"
                print("❌ [CONTENT VIEW] Error adding paper: \(error)")
            }
        }
    }

    func deletePaper(_ id: Int) {
        print("🗑️ [CONTENT VIEW] === DELETE PAPER STARTED ===")
        print("🗑️ [CONTENT VIEW] Paper ID: \(id)")
        
        Task {
            do {
                // Get current collection count before deleting
                let currentSelectedCount = selectedCollection?.papers.count ?? 0
                print("🗑️ [CONTENT VIEW] Current selected collection paper count: \(currentSelectedCount)")
                
                try await APIService.shared.deletePaper(id: id)
                print("✅ [CONTENT VIEW] Delete API call completed")
                
                // Remove from local state immediately
                selectedCollection?.papers.removeAll { $0.id == id }
                
                let newSelectedCount = selectedCollection?.papers.count ?? 0
                print("📊 [CONTENT VIEW] Local paper count: \(currentSelectedCount) → \(newSelectedCount)")
                
                print("🔄 [CONTENT VIEW] Refreshing collections after deleting paper...")
                // Add delay to ensure backend has processed the deletion
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                
                await MainActor.run {
                    loadCollections()
                }
            } catch {
                errorMessage = "Error deleting paper: \(error.localizedDescription)"
                print("❌ [CONTENT VIEW] Error deleting paper: \(error)")
            }
        }
    }
}
