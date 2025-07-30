//
//  Untitled.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import SwiftUI

struct NewPaperForm: View {
    let onSubmit: (SearchResultItem) -> Void
    @State private var title = ""
    @State private var source = ""
    @State private var url = ""
    @State private var abstract = ""
    @State private var authors = ""
    @State private var publicationDate = ""
    @State private var showForm = false

    var body: some View {
        VStack {
            Button("+ Add Paper Manually") {
                showForm.toggle()
            }
            .buttonStyle(.borderedProminent)

            if showForm {
                VStack(spacing: 12) {
                    TextField("Paper Title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextField("Source (Journal, Conference, etc.)", text: $source)
                        .textFieldStyle(.roundedBorder)

                    TextField("URL (optional)", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    TextField("Abstract (optional)", text: $abstract, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)

                    TextField("Authors (comma-separated, optional)", text: $authors)
                        .textFieldStyle(.roundedBorder)

                    TextField("Publication Date (YYYY-MM-DD, optional)", text: $publicationDate)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)

                    HStack {
                        Button("Cancel") {
                            resetForm()
                            showForm = false
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("Add Paper") {
                            // Create a SearchResultItem for manual entry
                            // Use nil for coreId to indicate this is NOT a CORE paper
                            let newSearchResult = SearchResultItem(
                                title: title,
                                abstract: abstract.isEmpty ? nil : abstract,
                                authors: authors.isEmpty ? nil : authors,
                                publicationDate: publicationDate.isEmpty ? nil : publicationDate,
                                source: source,
                                url: url.isEmpty ? nil : url,
                                downloadUrl: nil, // Manual papers don't have download URLs initially
                                coreId: nil, // nil indicates manual entry, not from CORE
                                likesCount: 0
                            )
                            onSubmit(newSearchResult)
                            resetForm()
                            showForm = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(title.isEmpty || source.isEmpty)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private func resetForm() {
        title = ""
        source = ""
        url = ""
        abstract = ""
        authors = ""
        publicationDate = ""
    }
}
