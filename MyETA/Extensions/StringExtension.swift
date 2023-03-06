import Foundation

extension String: LocalizedError {
    // Allows String values to be thrown.
    public var errorDescription: String? { self }

    func count(of string: String) -> Int {
        let char = string.first!
        return reduce(0) { $1 == char ? $0 + 1 : $0 }
    }

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
