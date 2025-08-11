//
//  CollectionView.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import SwiftUI

//This View receives state as props
struct CollectionView: View {
    //PROPS (State flowing DOWN from parent)
    let collection: Collection // Data about the collection
    let isSelected: Bool //True or False
    @Binding var selectedCollection: Collection? //The currently selected collection
    //Not PROPS, but functions passed (Actions flowing UP to ContentView)
    let onSelect: () -> Void // item was tapped/selected
    let onClose: () -> Void  //Close item
    let onDelete: () -> Void //Delete item
    let onAddPaper: (Int, SearchResultItem) -> Void //add paper
    let onDeletePaper: (Paper) -> Void //Delete paper item
    let onStarPaper: (Int) -> Void //Star/unstar paper item
    
    @State private var isDeletingPaper: Bool = false // Track paper deletion state

    var body: some View {
        VStack {
            //Collection has two modes: expanded and collapsed. If isSelected is True AND selectedCollection exists → do expanded view, otherwise do collapsed view
                
            // Using the 'isSelected' and 'selectedCollection' props
            //need to copy selected to a let variable so it can be accessed as non-optional
            if isSelected, let selected = selectedCollection {

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        //.title2 is a semantic font style
                        Text(selected.title).font(.title2) //selecting key title from collection
                        Spacer() //takes all middle space
                        // Close button (X).  closes the expanded view
                        Button("×") {
                            onClose() //when tapped, sends action up to ContentView, calls onClose closure which
                            //sets selectedCollection = nil
                        }
                        .font(.title2)
                        .foregroundColor(.gray)

                        // Delete button - deletes the entire collection
                        Button("🗑") {
                            onDelete() //when tapped, sends action up to ContentView, calls onDelete closure which
                            //calls the deleteCollection function which sends a delete request to the backend API
                            //if that collection was currently selected, it sets selectedCollection = nil
                        }
                        .foregroundColor(.red)
                    }
                    
                    Text(selected.description).font(.caption) //smallest font

                    // Form to manually add a new paper to the collection
                    NewPaperForm { searchResult in            //form sends paper as searchResult
                        onAddPaper(selected.id, searchResult) //calls onAddPaper (ContentView)
                    }

                    if selectedCollection?.papers.isEmpty ?? true {
                        Text("No papers in this collection yet.")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical)
                    } else {
                        //.count Swift array method
                        Text("Papers (\(selectedCollection?.papers.count ?? 0))") //selecting key papers from the collection
                            .font(.headline) // makes text bold and emphasized
                            .padding(.top) // adds space above the text
                        
                        LazyVStack(spacing: 12) {
                        ForEach(selectedCollection?.papers ?? []) { paper in     // ← use selectedCollection directly
                            PaperRow(paper: paper,                               // ← state flows down to PaperRow
                                     onDeletePaper: { paperToDelete in
                                         Task {
                                             await handlePaperDeletion(paperToDelete)
                                         }
                                     },                                          // ← async delete function
                                     onStarPaper: onStarPaper,                   // ← star callback flows up
                                     isDeleting: $isDeletingPaper)               // ← deletion state binding
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .contentShape(Rectangle()) // makes just single paper row fully clickable or the empty message
                .onTapGesture {
                    //prevents closing the collection when tapping inside collection view
                }
                
            //Collection has two modes: expanded and collapsed. If isSelected is False Or selectedCollection
            // doesn't exists → do collapsed view
            } else {
                // Collection preview (collapsed)
                VStack {
                    HStack {
                        Text(collection.title).font(.headline)
                        Spacer()
                        // Delete button for collapsed view
                        Button("×") {
                            onDelete()
                        }
                        .foregroundColor(.red)
                    }
                    Text("\(collection.papersCount) papers").font(.caption)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect() // Only opens, doesn't close
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Paper Deletion Handler
    private func handlePaperDeletion(_ paper: Paper) async {
        do {
            // Call the parent's delete paper function
            onDeletePaper(paper)
            
            // Wait a moment for the API call to complete
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Reset deletion state on success
            await MainActor.run {
                isDeletingPaper = false
            }
        } catch {
            // Reset deletion state on failure
            await MainActor.run {
                isDeletingPaper = false
            }
        }
    }
}
