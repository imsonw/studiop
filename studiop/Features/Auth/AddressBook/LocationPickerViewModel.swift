import CoreLocation
import Foundation

/// Backs the address form's "pick on map" affordance (Sprint 6, senior-skills-roadmap.md §9).
/// `CLLocationManager`'s delegate callbacks land off the main thread -- this class is
/// `@MainActor`, so each callback below hops back to it before touching `@Observable` state.
@MainActor
@Observable
final class LocationPickerViewModel: NSObject {
    private(set) var selectedCoordinate: CLLocationCoordinate2D?
    private(set) var resolvedAddress: String?
    var isResolving: Bool = false
    var errorMessage: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func select(coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        Task { await reverseGeocode(coordinate) }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async {
        isResolving = true
        errorMessage = nil
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
            resolvedAddress = placemarks.first.map(Self.formattedAddress)
        } catch {
            errorMessage = error.localizedDescription
        }
        isResolving = false
    }

    private static func formattedAddress(_ placemark: CLPlacemark) -> String {
        [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

extension LocationPickerViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            select(coordinate: location.coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}
