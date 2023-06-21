@propertyWrapper
struct Path<T: CustomStringConvertible>: PathDescribing {
    let wrappedValue: T
    let customName: String?

    var value: String { wrappedValue.description }

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
        self.customName = nil
    }

    init(wrappedValue: T, _ customName: String) {
        self.wrappedValue = wrappedValue
        self.customName = customName
    }
}
