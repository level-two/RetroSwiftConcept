import Foundation

final class UrlSessionNetworkService: NetworkService {
    func setConfiguration(
        scheme: String,
        host: String,
        sharedHeaders: [String: String]
    ) {
        self.scheme = scheme
        self.host = host
        self.sharedHeaders = sharedHeaders
    }

    func request<Response: Decodable>(
        httpMethod: String,
        path: String,
        headerParams: [String: String]?,
        queryParams: [String: String]?,
        body: Encodable?
    ) async throws -> Response {
        let urlRequest = try assembleURLRequest(
            httpMethod: httpMethod,
            path: path,
            headerParams: headerParams,
            queryParams: queryParams,
            body: body)

        return try await self.perform(request: urlRequest, object: Response.self)
    }

    private var scheme: String?
    private var host: String?
    private var sharedHeaders: [String: String]?

    private lazy var urlSession = URLSession(configuration: sessionConfiguration)
    private lazy var sessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.httpAdditionalHeaders = sharedHeaders
        return configuration
    }()

    private lazy var encoder = JSONEncoder()
    private lazy var decoder = JSONDecoder()
}

private extension UrlSessionNetworkService {
    func assembleURLRequest(
        httpMethod: String,
        path: String,
        headerParams: [String: String]?,
        queryParams: [String: String]?,
        body: Encodable?
    ) throws -> URLRequest {
        var urlComponents = URLComponents()

        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = queryParams?.map(URLQueryItem.init)

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod

        headerParams?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        return urlRequest
    }
}

private extension UrlSessionNetworkService {
    func perform<T: Decodable>(request: URLRequest, object: T.Type) async throws -> T {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.dataTask(request: request, object: object, continuation: continuation)
                .resume()
        }
    }

    func dataTask<T: Decodable>(
        request: URLRequest,
        object: T.Type,
        continuation: CheckedContinuation<T, Error>
    ) -> URLSessionDataTask {

        print("Request:")
        print(request.customDescription)

        return urlSession.dataTask(with: request) { data, response, error in
            print("Response:")
            print(response?.description ?? "")

            if let error = error {
                continuation.resume(throwing: error)
                return
            }

            guard let data else {
                continuation.resume(throwing: URLError(.dataNotAllowed))
                return
            }

            print("Body:")
            print(String(data: data, encoding: .utf8) ?? "")

            do {
                let object = try self.decoder.decode(T.self, from: data)
                continuation.resume(returning: object)
            } catch {
                continuation.resume(throwing: error)

                print("Decoding error:")
                print(error.localizedDescription)
            }
        }
    }
}

private extension URLRequest {
    var customDescription: String {
        var description = [] as [String]

        if let httpMethod {
            description.append("Method: \(httpMethod)")
        }

        if let url {
            description.append("URL: \(url)")
        }

        if let allHTTPHeaderFields, !allHTTPHeaderFields.isEmpty {
            description.append("Headers: \(allHTTPHeaderFields)")
        }

        if let httpBody {
            description.append("Body: \(httpBody)")
        }

        return description.joined(separator: "\n")
    }
}
