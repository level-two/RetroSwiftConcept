import Foundation

public protocol NetworkProviding: AnyObject {
    func perform<Request, Response: Decodable>(
        request: Request,
        to endpoint: EndpointDescribing
    ) async throws -> Response
}
