//
//  CollectionView.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import SwiftUI

//This View receives state as props, delegates actions back up
struct CollectionView: View {
    let collection: Collection
    let isSelected: Bool
    let selectedCollection: Collection?
    let onSelect: () -> Void
    let onClose: () -> Void
    let onDelete: () -> Void
    let onAddPaper: (Int, SearchResultItem) -> Void
    let onDeletePaper: (Int) -> Void

    var body: some View {
        VStack {
            if isSelected, let selected = selectedCollection {
                // Full collection view (expanded)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selected.title).font(.title2)
                        Spacer()
                        // Close button (X) - closes the expanded view
                        Button("×") {
                            onClose()
                        }
                        .font(.title2)
                        .foregroundColor(.gray)

                        // Delete button - deletes the entire collection
                        Button("🗑") {
                            onDelete()
                        }
                        .foregroundColor(.red)
                    }
                    
                    Text(selected.description).font(.caption)

                    // Form to manually add a new paper to the collection
                    NewPaperForm { searchResult in
                        onAddPaper(selected.id, searchResult)
                    }

                    // FIXED: Remove ScrollView - let the parent ContentView handle scrolling
                    if selected.papers.isEmpty {
                        Text("No papers in this collection yet.")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical)
                    } else {
                        Text("Papers (\(selected.papers.count))")
                            .font(.headline)
                            .padding(.top)
                        
                        // FIXED: Use LazyVStack without ScrollView - parent will handle scrolling
                        LazyVStack(spacing: 12) {
                            ForEach(selected.papers) { paper in
                                PaperRow(paper: paper, onDeletePaper: onDeletePaper)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .contentShape(Rectangle()) // Prevents tap gesture from bubbling up
                .onTapGesture {
                    // Do nothing - prevent closing when tapping inside expanded view
                }
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
}
