import MapKit
import SwiftUI

/// "Pick on map" affordance for the address form (Sprint 6, senior-skills-roadmap.md §9) --
/// SwiftUI's `Map`/`MapReader` (iOS 17+), not the older `MKMapView` UIKit wrapper. Writes back a
/// plain display string via `onConfirm` -- `Address.location` (Domain) stays a `String`; all the
/// coordinate/placemark handling lives here in Presentation.
struct LocationPickerView: View {
    @State private var viewModel = LocationPickerViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @Environment(\.dismiss) private var dismiss
    let onConfirm: (String) -> Void

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let coordinate = viewModel.selectedCoordinate {
                        Marker("Selected location", coordinate: coordinate)
                    }
                }
                .onTapGesture { screenPoint in
                    guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                    viewModel.select(coordinate: coordinate)
                }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 8) {
                    if viewModel.isResolving {
                        ProgressView()
                            .padding(8)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    } else if let resolvedAddress = viewModel.resolvedAddress {
                        Text(resolvedAddress)
                            .font(.caption)
                            .padding(8)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Use this location") {
                        guard let resolvedAddress = viewModel.resolvedAddress else { return }
                        onConfirm(resolvedAddress)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.resolvedAddress == nil || viewModel.isResolving)
                }
                .padding()
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Current Location") {
                        viewModel.requestCurrentLocation()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    LocationPickerView(onConfirm: { _ in })
}
