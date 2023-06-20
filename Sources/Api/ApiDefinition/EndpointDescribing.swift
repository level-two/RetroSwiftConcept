public typealias EndpointDescribing = PathProviding & MethodProviding

public protocol PathProviding {
    var path: String { get }
}

public protocol MethodProviding {
    var method: HttpMethod { get }
}
