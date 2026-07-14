import Foundation

/// Per `GET /location/list/country?token=` — cacheable.
protocol LocationRepository {
    func fetchCountryList() async throws -> [Country]
}
