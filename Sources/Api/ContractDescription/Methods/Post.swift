import Foundation

@propertyWrapper
class Post<Request, Response: Decodable>: EndpointDescribing {
    typealias NetworkAction = (Request) async throws -> Response

    let path: String
    var method: HttpMethod { .post }

    init(_ path: String) {
        self.path = path
    }

    static subscript<EnclosingInstance: NetworkProviding>(
        _enclosingInstance instance: EnclosingInstance,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingInstance, NetworkAction>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingInstance, Post>
    ) -> NetworkAction {
        get {
            if let customAction = instance[keyPath: storageKeyPath].customAction {
                return customAction
            }
            return { try await instance.perform(request: $0, to: instance[keyPath: storageKeyPath]) }
        }
        set {
            instance[keyPath: storageKeyPath].customAction = newValue
        }
    }

    @available(*, unavailable)
    var wrappedValue: NetworkAction {
        get { fatalError("only works on instance properties of classes") }
        // swiftlint:disable:next unused_setter_value
        set { fatalError("only works on instance properties of classes") }
    }

    private var customAction: NetworkAction?
}
