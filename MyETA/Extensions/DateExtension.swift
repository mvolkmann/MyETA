import Foundation

extension Date {
    var time: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:m a"
        return dateFormatter.string(from: self)
    }
}
