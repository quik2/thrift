import SwiftUI

/// Centralized SF Symbol mapping for all icons used in ThriftFlip.
/// All icons use SF Symbols exclusively — no custom image assets in MVP.
enum TFIcon {

    // MARK: - Tab Bar

    static let scanTab = "camera"
    static let scanTabFilled = "camera.fill"
    static let collectionTab = "square.stack"
    static let collectionTabFilled = "square.stack.fill"
    static let sellTab = "tag"
    static let sellTabFilled = "tag.fill"

    // MARK: - Navigation & Actions

    static let profile = "person.circle"
    static let profileFilled = "person.circle.fill"
    static let settings = "gearshape"
    static let settingsFilled = "gearshape.fill"
    static let dismiss = "xmark"
    static let back = "chevron.left"
    static let forward = "chevron.right"
    static let share = "square.and.arrow.up"
    static let more = "ellipsis"
    static let filter = "line.3.horizontal.decrease"

    // MARK: - Scan Screen

    static let flash = "bolt.fill"
    static let flashOff = "bolt.slash.fill"
    static let gallery = "photo.on.rectangle"
    static let cameraFlip = "arrow.triangle.2.circlepath.camera"
    static let scanViewfinder = "camera.viewfinder"
    static let textViewfinder = "text.viewfinder"

    // MARK: - Confidence

    static let checkmarkCircle = "checkmark.circle.fill"
    static let warningTriangle = "exclamationmark.triangle.fill"
    static let questionCircle = "questionmark.circle"
    static let infoCircle = "info.circle"

    // MARK: - Trends & Stats

    static let trendUp = "arrow.up.right"
    static let trendDown = "arrow.down.right"
    static let trendNeutral = "arrow.right"
    static let chart = "chart.line.uptrend.xyaxis"
    static let chartFilled = "chart.line.uptrend.xyaxis.circle.fill"

    // MARK: - Collection & Items

    static let heart = "heart"
    static let heartFilled = "heart.fill"
    static let trash = "trash"
    static let trashFilled = "trash.fill"
    static let edit = "pencil"
    static let correct = "pencil.line"
    static let duplicate = "doc.on.doc"
    static let magnifyingGlass = "magnifyingglass"

    // MARK: - Sell & Listings

    static let listing = "list.bullet"
    static let dollarSign = "dollarsign.circle"
    static let dollarSignFilled = "dollarsign.circle.fill"
    static let link = "link"
    static let externalLink = "arrow.up.right.square"
    static let ebayCart = "cart"
    static let ebayCartFilled = "cart.fill"

    // MARK: - Empty & Error States

    static let emptyScans = "camera.viewfinder"
    static let emptyComps = "magnifyingglass"
    static let emptyOCR = "text.viewfinder"
    static let offline = "wifi.slash"
    static let rateLimited = "lock.fill"
    static let errorGeneric = "exclamationmark.triangle.fill"
    static let photo = "photo"

    // MARK: - Garment Type Icons (decorative overlays)

    static let outerwear = "cloud.fill"
    static let bottoms = "figure.walk"
    static let tops = "tshirt.fill"
    static let accessories = "eyeglasses"
    static let shoes = "shoe.fill"
    static let genericGarment = "hanger"

    // MARK: - Paywall

    static let featureIncluded = "checkmark.circle.fill"
    static let featureExcluded = "xmark.circle"
    static let crown = "crown.fill"
    static let sparkle = "sparkles"
    static let unlimited = "infinity"

    // MARK: - Misc

    static let copy = "doc.on.clipboard"
    static let save = "square.and.arrow.down"
    static let refresh = "arrow.clockwise"
    static let calendar = "calendar"
    static let clock = "clock"
    static let location = "mappin"

    // MARK: - Helpers

    /// Returns the garment type icon based on garment type string.
    static func garmentIcon(for garmentType: String) -> String {
        switch garmentType.lowercased() {
        case "fleece", "jacket", "coat", "puffer", "vest":
            return outerwear
        case "joggers", "pants", "jeans", "shorts", "trousers":
            return bottoms
        case "shirt", "tee", "sweater", "hoodie", "polo", "blouse":
            return tops
        case "hat", "scarf", "belt", "bag", "watch", "sunglasses":
            return accessories
        case "sneakers", "boots", "loafers", "sandals":
            return shoes
        default:
            return genericGarment
        }
    }
}
