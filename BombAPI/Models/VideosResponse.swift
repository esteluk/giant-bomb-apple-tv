public struct WrappedResponse<T: Decodable>: Decodable {
    enum CodingKeys: String, CodingKey {
        case numberOfTotalResults = "number_of_total_results"
        case pageSize = "number_of_page_results"
        case results
    }

    public let numberOfTotalResults: Int
    public let pageSize: Int
    public let results: T
}
