import SwiftUI

struct SellView: View {
    var body: some View {
        VStack(spacing: 0) {
            AppHeader(title: "Sell", subtitle: "eBay Listings")

            EmptyStateCard(
                icon: "tag.fill",
                title: "No listings yet",
                message: "Save a scan result, then list it directly to eBay from your collection.",
                actionLabel: "Go to My Finds",
                action: {}
            )
        }
        .background(Color.tfBackground)
    }
}

#Preview {
    SellView()
        .preferredColorScheme(.dark)
}
