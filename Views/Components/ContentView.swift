//
//  ContentView.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import SwiftUI

// ContentView.swift (PARENT)
struct ContentView: View { //App view starts here
    // ContentView has the data
    @State private var collections: [Collection] = []                 // ← Parent owns the state
    @State private var selectedCollection: Collection? = nil          // ← Parent owns the state
    @State private var showAddForm = false
    @State private var showSearchSheet = false
    @State private var showNetworkView = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {                                  // ← CONTAINER that provides navigation context
            VStack(spacing: 0) {                          // creates a vertical stack == full page layout
                // header section (not scrollable)
                VStack {                                  // Header group
                    Text("Research Collections")
                        .font(.largeTitle)
                        .padding()

                    if !errorMessage.isEmpty {             //if error is not NOT empty
                        Text(errorMessage)                 // print message
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    HStack {                              //creates a horizontal stack w/4 buttons
                                                          // Each button sets a Bool state variable to true
                        Button("➕ Create New Collection") {
                            showAddForm = true            //controls whether the pop-up (sheet) is visible
                        }
                        .padding()

                        Button("🔍 Search Core API") {
                            showSearchSheet = true        //controls whether the pop-up (sheet) is visible
                        }
                        .padding()
                        
                        Button("Idea Analysis") {
                            showNetworkView = true        //controls whether the pop-up (sheet) is visible
                        }
                        .padding()
                        
                    }
                }
                .background(Color(.systemBackground))    // uses the system’s default background color
                
                // Scrollable collections section starts here
                ScrollView {
                    //LazyVStack only creates views when they're about to appear on screen (lazy loading)
                    LazyVStack(spacing: 16) {
                        ForEach(collections) { collection in        // ← DATA iteration is happaning
                            CollectionView(                         // ← Parent CREATES child
                                collection: collection,             // ← Parent PASSES state down
                                // ?. If selectedCollection exists, get its .id
                                //If selectedCollection.id is equal to collection.id, then set isSelected
                                //to true. Otherwise, false
                                isSelected: selectedCollection?.id == collection.id,
                                selectedCollection: selectedCollection,
                                onSelect: {                         // ← ContedntView HANDLES actions
                                    selectCollection(collection)    // ContentView CALLS this function
                                },
                                onClose: {
                                    selectedCollection = nil        //ContentView SETS state variable to nil
                                },
                                onDelete: {
                                    deleteCollection(collection.id) //ContentView CALLS this function
                                },
                                //Shorthand for: onAddPaper: { addPaper($0, $1) }
                                onAddPaper: addPaper, //addPaper($0, $1) means pass the first and second
                                // arguments that the child sends up to the addPaper function
                                
                                // Shorthand for: onDeletePaper: { deletePaper($0) }
                                onDeletePaper: deletePaper
                            )
                            .id(collection.id)  //Use this existing unique ID value from my data (collection.id)
                            //as the identity (name tag) for this view
                        }
                    }
                    .padding()
                }
            }
        }
        //Starts the data flow. When ContentView appears, collections might be empty or outdated.
        // SwiftUI calls loadCollections() once to fetch/load the collections list with fresh, up-to-date data
        .task { loadCollections() } //view modifier attached it directly to a View
        .sheet(isPresented: $showAddForm) { //view modifier. When showAddForm is true, show a sheet (pop-up)
            // inside it, show the NewCollectionForm view
            //This is a closure (lambda in other languages) defining a mini function right inside the code
            NewCollectionForm { title, owner, description in // This is input to the closure
                //when the user submits the form, call the createCollection(...) function with the form’s values
                createCollection(title: title, owner: owner, description: description)
            }
        }
        .sheet(isPresented: $showSearchSheet) { //view modifier. When showSearchSheet is true, -> (pop-up)
            CoreAPISearchView(                                      // ContentView(Parent) → CoreAPISearchView
                selectedCollection: $selectedCollection,            // ← Two-way binding (special case)
                onAddPaperToCollection: addPaper                    // ← Callback flows up
            )
        }
        .fullScreenCover(isPresented: $showNetworkView) { //view modifier. When ... true, -> (pop-up-full screen)
            IdeaAnalysisView {
                showNetworkView = false
            }
        }
        // watches the showSearchSheet Boolean state
        .onChange(of: showSearchSheet) {
            if !showSearchSheet { //only run when showSearchSheet becomes false
                //meaning the search sheet (pop-up) is closed
                Task {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    //after the wait, run loadCollections() on the main thread, and update the UI
                    await MainActor.run {
                        loadCollections()
                    }
                }
            }
        }
    }

    // MARK: - Actions
    
    //First State Load. The UI stays responsive — animations, taps, scrolls still work
    //this function called above .task { loadCollections() }
    //loadCollections() is called in the background, and the function is suspended at await
    //until the data returns (just like promise)
    func loadCollections() {
        Task {
            do {
                //Try to fetch the data from the shared API service. store the result in newCollections
                // .shared a singleton pattern, a way to create one shared instance of a class
                //that can be used throughout your app
                let newCollections = try await APIService.shared.loadCollections()
                //When the result is ready and it is True, resume execution , using MainActor.run
                // switch to the main thread and update the UI
                await MainActor.run {
                    collections = newCollections // ← STATE FLOWS DOWN from here → CollectionView (State Passing)
                }
                // When an error happens, switch to the main thread using MainActor.run
                // and update the UI by setting the error message
            } catch {
                await MainActor.run {
                    //localizedDescription is a property of the error that provides a user-friendly
                    //description of what caused the error, displaid in the UI
                    //The \(...) syntax is used inside a string to insert the value of
                    //variable, expression, or function call
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
                    var updatedCollection = collection //makes a copy of the existing collection obj
                    updatedCollection.papers = papers // replaces the old papers with a new list of papers
                    selectedCollection = updatedCollection // updates the state variable selectedCollection
                    //to the new collection with the updated papers
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
                //calls a function that sends the new collection data to a backend server (API) to save it
                //it waits until the server finishes
                try await APIService.shared.createCollection(title: title, owner: owner, description: description)
                
                await MainActor.run { //when the server is done, this switches back to the main UI thread to
                    showAddForm = false //closes the form
                    loadCollections()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error creating collection: \(error.localizedDescription)"
                }
            }
        }
    }

    //_ id means no need to write the parameter name when calling the function,just pass the value directly
    func deleteCollection(_ id: Int) {
        Task {
            do {
                try await APIService.shared.deleteCollection(id: id)
                
                await MainActor.run {
                    //$0 is shorthand syntax in Swift for the first argument passed into a closure
                    // removes all items from the collections array where the item's id matches the given id
                    collections.removeAll { $0.id == id }
                    //? if selectedCollection exists, then check its .id
                    if selectedCollection?.id == id {
                        selectedCollection = nil //clears the selection
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
                //adds a new paper to the backend database (via API)
                try await APIService.shared.addPaper(collectionId: collectionId, searchResult: searchResult)
                
                // refreshes the selected collection to show new paper
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
        Task { //creates an async task to handle the deletion without blocking the UI
            do {
                //calls the backend API to actually delete the paper from the database
                try await APIService.shared.deletePaper(id: id)
                
                // if collection is selected, refresh selected collection to remove deleted paper
                if let selected = selectedCollection {
                    selectCollection(selected)
                }
                
                // refresh collections list to update paper counts
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
