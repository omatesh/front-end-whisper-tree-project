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
                                onDelete: {
                                    deleteCollection(collection.id)
                                },
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
        //Starts teh app. When ContentView appears, SwiftUI calls loadCollections()
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
        .onChange(of: showSearchSheet) {
            if !showSearchSheet {
                Task {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        loadCollections()
                    }
                }
            }
        }
    }

    // MARK: - Actions
    
    //First State Load. The UI stays responsive — animations, taps, scrolls still work
    //loadCollections() is called in the background, and the function is suspended at await
    //until the data returns (just like promise)
    func loadCollections() {
        Task {
            do {
                //Try to fetch the data from the shared API service. store the result in newCollections
                // .shared a singleton pattern, a way to create one shared instance of a class that can be
                //used throughout your app
                let newCollections = try await APIService.shared.loadCollections()
                //When the result is ready and it is True, resume execution , using MainActor.run
                // switch to the main thread and update the UI
                await MainActor.run {
                    collections = newCollections // ← STATE FLOWS DOWN from here
                }
                // When an error happens, switch to the main thread using MainActor.run
                // and update the UI by setting the error message
            } catch {
                await MainActor.run {
                    //localizedDescription is a property of the error that provides a user-friendly
                    //description of what caused the error, displaid in the UI
                    errorMessage = "Error loading collections: \(error.localizedDescription)"
                }
            }
        }
    }

    func selectCollection(_ collection: Collection) {
        Task {
            do {
                let papers = try await APIService.shared.fetchPapers(for: collection.id)

                await MainActor.run {
                    var updatedCollection = collection
                    updatedCollection.papers = papers
                    selectedCollection = updatedCollection
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error loading papers: \(error.localizedDescription)"
                }
            }
        }
    }

    func createCollection(title: String, owner: String, description: String) {
        Task {
            do {
                try await APIService.shared.createCollection(title: title, owner: owner, description: description)
                
                await MainActor.run {
                    showAddForm = false
                    loadCollections()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error creating collection: \(error.localizedDescription)"
                }
            }
        }
    }

    func deleteCollection(_ id: Int) {
        Task {
            do {
                try await APIService.shared.deleteCollection(id: id)
                
                await MainActor.run {
                    collections.removeAll { $0.id == id }
                    if selectedCollection?.id == id {
                        selectedCollection = nil
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error deleting collection: \(error.localizedDescription)"
                }
            }
        }
    }

    func addPaper(collectionId: Int, searchResult: SearchResultItem) {
        Task {
            do {
                try await APIService.shared.addPaper(collectionId: collectionId, searchResult: searchResult)
                
                // Refresh the selected collection to show new paper
                if let selected = selectedCollection, selected.id == collectionId {
                    let papers = try await APIService.shared.fetchPapers(for: collectionId)
                    
                    await MainActor.run {
                        var updatedCollection = selected
                        updatedCollection.papers = papers
                        selectedCollection = updatedCollection
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error adding paper: \(error.localizedDescription)"
                }
            }
        }
    }

    func deletePaper(_ id: Int) {
        Task {
            do {
                try await APIService.shared.deletePaper(id: id)
                
                // Refresh selected collection to remove deleted paper
                if let selected = selectedCollection {
                    selectCollection(selected)
                }
                
                // Refresh collections list to update paper counts
                await MainActor.run {
                    loadCollections()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Error deleting paper: \(error.localizedDescription)"
                }
            }
        }
    }
}
