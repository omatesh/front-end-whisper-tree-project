//
//  PaperRow.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import SwiftUI

//Pure presentation component with callback-based actions
struct PaperRow: View {
    let paper: Paper // view data
    let onDeletePaper: (Paper) -> Void // delete action
    let onStarPaper: (Int) -> Void // star toggle action
    @Binding var isDeleting: Bool // Shared deletion state from parent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(paper.title)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                //it checks if paper.source has a value (not nil) and
                //!source.isEmpty it is not empty
                if let source = paper.source, !source.isEmpty {
                    Text("Source: \(source)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Source: Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Display authors if available
                if let authors = paper.authors, !authors.isEmpty {
                    Text("Authors: \(authors)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Display publication date if available
                if let pubDate = paper.publicationDate, !pubDate.isEmpty {
                    Text("Published: \(pubDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Show CORE ID if this is a CORE paper
                if let coreId = paper.coreId, !coreId.isEmpty {
                    Text("CORE ID: \(coreId)")
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(0.7))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(3)
                }

                // Link section
                HStack(spacing: 8) {
                    // Regular URL link
                    //Tries to create a URL object from the urlString
                    if let urlString = paper.url, !urlString.isEmpty, let url = URL(string: urlString) {
                        Link(destination: url) {
                            Text("View")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    // Download URL link (for PDFs from CORE)
                    if let downloadUrlString = paper.downloadUrl, !downloadUrlString.isEmpty, let downloadUrl = URL(string: downloadUrlString) {
                        Link(destination: downloadUrl) {
                            Text("PDF")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                    
                    // Show message if no links are available
                    if (paper.url?.isEmpty ?? true) && (paper.downloadUrl?.isEmpty ?? true) {
                        Text("No links available")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                // Star/unstar button
                Button(action: {
                    onStarPaper(paper.id)
                }) {
                    Text(paper.likesCount > 0 ? "★" : "☆")
                        .font(.title2)
                        .foregroundColor(paper.likesCount > 0 ? .yellow : .gray)
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: {
                    guard !isDeleting else { return } // Prevent multiple taps
                    
                    print("PaperRow: Delete button tapped for paper ID: \(paper.id), title: \(paper.title)")
                    isDeleting = true // Immediately disable button
                    onDeletePaper(paper) // Call delete function
                }) {
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    } else {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .disabled(isDeleting) // Disable button while deleting
                .buttonStyle(BorderlessButtonStyle())
                .padding(4)
                .background(Circle().fill(Color.red.opacity(isDeleting ? 0.05 : 0.1)))
                .contentShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

