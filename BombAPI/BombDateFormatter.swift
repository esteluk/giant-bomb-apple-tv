import Foundation

extension DateFormatter {
    static var defaultBombFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return formatter
    }
}
