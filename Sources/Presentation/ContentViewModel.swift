import Combine
import Foundation

@MainActor
final class ContentViewModel: ObservableObject {
    @Published private(set) var loading = false
    @Published var error = nil as String?
    @Published var artist = "Molchat Doma"
    @Published var corruptAppId = false
    @Published private(set) var details = ""

    init(api: BandsInTownApi) {
        self.api = api
    }

    func find() {
        Task {
            loading = true
            details = ""

            do {
                let artistDetails = try await api.findArtist(.init(artistName: artist, appId: "123"))

                let eventsResponse = try await api.artistEvents(
                    ArtistEventsRequest(
                        artistName: artist,
                        appId: corruptAppId ? "fffff" : "123",
                        date: "2023-05-05,2023-09-05")
                )

                switch eventsResponse {
                case .response(let events):
                    details = "\(artistDetails.description)\n\nEvents:\n\(events.description)"
                case .errorResponse(let errorResponse):
                    error = errorResponse.errorMessage
                }
            } catch {
                self.error = error.localizedDescription
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
