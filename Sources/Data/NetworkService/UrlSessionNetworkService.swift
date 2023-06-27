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

        if let body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        return urlRequest
    }
}

private extension UrlSessionNetworkService {
    func perform<Response: Decodable>(request: URLRequest, object: Response.Type) async throws -> Response {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.dataTask(request: request, object: object, continuation: continuation)
                .resume()
        }
    }

    func dataTask<Response: Decodable>(
        request: URLRequest,
        object: Response.Type,
        continuation: CheckedContinuation<Response, Error>
    ) -> URLSessionDataTask {

        print("Request:")
        print(request.customDescription)

        return urlSession.dataTask(with: request) { data, response, error in
            print("Response:")
            print(response?.description ?? "")

            if let error {
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
                let decoder = JSONDecoder()

                if Response.self is ErrorResponseDecoding.Type,
                   let urlResponse = response as? HTTPURLResponse
                {
                    let isSuccess = (200...299).contains(urlResponse.statusCode)
                    decoder.userInfo[ErrorResponseDecodingKey.isErrorResponseCodingKey] = !isSuccess
                }

                let object = try decoder.decode(Response.self, from: data)
                continuation.resume(returning: object)
            } catch {
                continuation.resume(throwing: error)

                print("Decoding error:")
                print(error.localizedDescription)
            }
        }
    }
}

private protocol ErrorResponseDecoding { }

private enum ErrorResponseDecodingKey {
    static var isErrorResponseCodingKey: CodingUserInfoKey {
        .init(rawValue: #function)!
    }
}

extension Either: Decodable, ErrorResponseDecoding {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if decoder.userInfo[ErrorResponseDecodingKey.isErrorResponseCodingKey] as? Bool == true {
            self = try .errorResponse(container.decode(ErrorResponse.self))
        } else {
            self = try .response(container.decode(Response.self))
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
