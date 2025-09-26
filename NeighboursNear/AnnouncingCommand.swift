import FoundationModels

@Generable(description: "arrays of announcings and suggestions to make announcings fuller")
struct AnnouncingsWithSuggestions: Codable, Equatable {
    @Guide(description: "array of announcings")
    let announcings: [Announcing]
    @Guide(description: "suggestions to make announcing fuller by id")
    let suggestions: [AnnouncingSuggestion]
}

@Generable(description: "announcing suggestion to make fuller announcing like photo, price, or details like 'model number' etc")
enum AnnouncingSuggestion: Codable, Equatable {
    case addPhoto, addPrice, addMoreDetails(detailName: String)
}

@Generable
struct Announcing: Codable, Identifiable, Equatable {
    @Guide(description: "unique id")
    let id: String
    @Guide(description: "price like 100 Tenge or Free, etc")
    let price: String
    @Guide(description: "type of announcing")
    let type: `Type`
    @Guide(description: "summorized details")
    let details: String
    @Guide(description: "photos ids")
    let photos: [String]
    
    @Generable
    enum `Type`: String, Codable, Equatable {
        case give, take
    }
}
