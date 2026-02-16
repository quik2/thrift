import SwiftUI

enum Tab: String {
    case scan
    case collection
    case sell
}

struct ContentView: View {
    @State private var selectedTab: Tab = .collection

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: selectedTab == .scan ? "camera.fill" : "camera")
                }
                .tag(Tab.scan)

            CollectionView()
                .tabItem {
                    Label("My Finds", systemImage: selectedTab == .collection ? "square.stack.fill" : "square.stack")
                }
                .tag(Tab.collection)

            SellView()
                .tabItem {
                    Label("Sell", systemImage: selectedTab == .sell ? "tag.fill" : "tag")
                }
                .tag(Tab.sell)
        }
        .tint(TFColor.gainGreen)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
