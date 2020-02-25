struct WrappedResponse<T: Decodable>: Decodable {
    let results: [T]
}
