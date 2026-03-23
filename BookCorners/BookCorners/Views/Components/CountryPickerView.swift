//
//  CountryPickerView.swift
//  BookCorners
//

import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedCountryCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var allCountries: [CountryItem] = []

    private var filteredCountries: [CountryItem] {
        if searchText.isEmpty {
            return allCountries
        }
        return allCountries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search countries", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            List {
                ForEach(filteredCountries, id: \.code) { country in
                    countryRow(country)
                }
            }
        }
        .navigationTitle("Country")
        .onAppear {
            if allCountries.isEmpty {
                allCountries = Locale.Region.isoRegions
                    .map { region in
                        let code = region.identifier
                        let name = Locale.current.localizedString(forRegionCode: code) ?? code
                        return CountryItem(code: code, name: name)
                    }
                    .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            }
        }
    }

    private func countryRow(_ country: CountryItem) -> some View {
        Button {
            selectedCountryCode = country.code
            dismiss()
        } label: {
            HStack {
                Text("\(country.name) (\(country.code))")
                    .foregroundStyle(.primary)
                Spacer()
                if country.code == selectedCountryCode {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

private struct CountryItem {
    let code: String
    let name: String
}
