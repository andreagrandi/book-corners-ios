//
//  FilterSheetView.swift
//  BookCorners
//

import SwiftUI

struct FilterSheetView: View {
    @Binding var filterState: FilterState
    var onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.apiClient) private var apiClient
    @State private var countries: [CountryCount] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    TextField("Keywords", text: $filterState.keywords)
                }

                Section("Location") {
                    TextField("City", text: $filterState.city)
                    Picker("Country", selection: $filterState.country) {
                        Text("Any").tag("")
                        ForEach(countries, id: \.countryCode) { country in
                            Text("\(country.countryName) (\(country.countryCode))")
                                .tag(country.countryCode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    TextField("Postal Code", text: $filterState.postalCode)
                }

                Section("Radius") {
                    Picker("Radius", selection: $filterState.radiusKm) {
                        Text("5 km").tag(5)
                        Text("10 km").tag(10)
                        Text("25 km").tag(25)
                        Text("50 km").tag(50)
                        Text("100 km").tag(100)
                    }
                }

                Section {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    Button("Clear", role: .destructive) { filterState.clear() }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if countries.isEmpty {
                do {
                    let stats = try await apiClient.getStatistics()
                    countries = stats.topCountries
                } catch {}
            }
        }
    }
}
