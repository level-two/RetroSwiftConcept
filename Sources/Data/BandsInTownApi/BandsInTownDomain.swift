import Foundation

class BandsInTownDomain: NetworkProviding {
    required init(networkService: NetworkService) {
        self.networkService = networkService

        networkService.setConfiguration(
            scheme: "https",
            host: "rest.bandsintown.com",
            sharedHeaders: ["Content-Type": "application/json"])
    }

    func perform<Request, Response: Decodable>(
        request: Request,
        to endpoint: EndpointDescribing
    ) async throws -> Response {

        try await networkService
            .request(
                httpMethod: endpoint.method.asString,
                path: resolvePath(format: endpoint.path, params: request),
                headerParams: getHeaderParams(from: request),
                queryParams: getQueryParams(from: request),
                body: getBody(from: request))
    }

    private let networkService: NetworkService
}

private extension HttpMethod {
    var asString: String {
        switch self {
        case .delete: return "DELETE"
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        }
    }
}
