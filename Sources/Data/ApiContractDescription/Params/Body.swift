import Foundation

@propertyWrapper
struct Body<T: Encodable>: BodyDescribing {
    let wrappedValue: T

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}
