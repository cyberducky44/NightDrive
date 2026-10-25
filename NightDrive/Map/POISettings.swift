import Foundation

/// OpenMapTiles classes, grouped for real-world map use rather than game missions.
enum POICategory: String, CaseIterable, Identifiable {
    case parking, fuel, food, transport, shopping, health, sights, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .parking: return "Parking"
        case .fuel: return "Fuel & charging"
        case .food: return "Food & drink"
        case .transport: return "Public transport"
        case .shopping: return "Shops"
        case .health: return "Health"
        case .sights: return "Sights & leisure"
        case .other: return "Other places"
        }
    }
    var classes: [String] {
        switch self {
        case .parking: return ["parking"]
        case .fuel: return ["fuel"]
        case .food: return ["cafe", "restaurant", "fast_food", "bar", "beer", "ice_cream"]
        case .transport: return ["bus", "railway", "entrance", "ferry_terminal", "harbor", "aerialway"]
        case .shopping: return ["shop", "grocery", "clothing_store", "alcohol_shop", "bakery", "butcher", "convenience", "mall"]
        case .health: return ["hospital", "pharmacy", "doctor", "dentist"]
        case .sights: return ["attraction", "museum", "monument", "castle", "art_gallery", "theatre", "cinema", "park", "zoo", "stadium", "library"]
        case .other: return []
        }
    }
    static var knownClasses: [String] { allCases.flatMap(\.classes) }
}

enum POIDensity: String, CaseIterable, Identifiable {
    case light, balanced, detailed
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    func maximumRank(at zoom: Double) -> Int {
        switch self {
        case .light: return zoom < 17 ? 2 : zoom < 18 ? 4 : 8
        case .balanced: return zoom < 17 ? 5 : zoom < 18 ? 12 : 24
        case .detailed: return zoom < 17 ? 10 : zoom < 18 ? 30 : 60
        }
    }
}

struct POISettings: Equatable {
    var enabled = false
    var categories: Set<POICategory> = [.parking, .fuel, .food, .sights]
    var density: POIDensity = .light
    var showsNames = false

    func predicate(at zoom: Double) -> NSPredicate {
        let classes = categories.sorted { $0.rawValue < $1.rawValue }.flatMap(\.classes)
        var choices: [NSPredicate] = []
        if !classes.isEmpty { choices.append(NSPredicate(format: "%K IN %@", "class", classes)) }
        if categories.contains(.other) {
            choices.append(NSCompoundPredicate(notPredicateWithSubpredicate:
                NSPredicate(format: "%K IN %@", "class", POICategory.knownClasses)))
        }
        let categoryFilter = choices.isEmpty ? NSPredicate(value: false) : NSCompoundPredicate(orPredicateWithSubpredicates: choices)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "name != nil"),
            // Filter before symbol placement, rather than hiding already-laid-out labels.
            NSPredicate(format: "rank <= %d", density.maximumRank(at: zoom)), categoryFilter
        ])
    }
}
