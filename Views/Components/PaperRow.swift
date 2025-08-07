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
    let onDeletePaper: (Int) -> Void // view action

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
                            HStack(spacing: 2) {
                                Image(systemName: "link")
                                Text("View")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    // Download URL link (for PDFs from CORE)
                    if let downloadUrlString = paper.downloadUrl, !downloadUrlString.isEmpty, let downloadUrl = URL(string: downloadUrlString) {
                        Link(destination: downloadUrl) {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.down.doc")
                                Text("PDF")
                            }
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
                // Display stars with a star graphic icon
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(paper.likesCount)")
                }
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.yellow.opacity(0.2)))

                Button(action: {
                    onDeletePaper(paper.id)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(4)
                .background(Circle().fill(Color.red.opacity(0.1)))
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

#Preview {
    VStack {
        // mock data
        // or sample data from the app
        Text("Paper rows would appear here")
            .foregroundColor(.secondary)
        
        // Plaseholder
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
