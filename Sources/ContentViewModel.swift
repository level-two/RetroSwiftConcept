import Combine
import Foundation

@MainActor
final class ContentViewModel: ObservableObject {
    @Published private(set) var loading = false
    @Published var error = nil as Error?
    @Published var artist = "Molchat Doma"
    @Published private(set) var details = ""

    init(api: BandsInTownApi) {
        self.api = api
    }

    func find() {
        Task {
            do {
                loading = true
                let artistDetails = try await api.findArtist(.init(artistName: artist, appId: "123"))
                let events = try await api.artistEvents(.init(artistName: artist, appId: "123", date: "2023-05-05,2023-09-05"))

                details = "\(artistDetails.description)\n\nEvents:\n\(events.description)"
            } catch {
                self.error = error
            }
            loading = false
        }
    }

    private let api: BandsInTownApi
}

private extension FindArtistResponse {
    var description: String {
        [name, url].joined(separator: "\n")
    }
}

private extension ArtistEventsResponse {
    var description: String {
        eventsList
            .map { event in [event.dateTime] + event.lineup }
            .map { $0.joined(separator: "\n") }
            .joined(separator: "\n\n")
    }
}
