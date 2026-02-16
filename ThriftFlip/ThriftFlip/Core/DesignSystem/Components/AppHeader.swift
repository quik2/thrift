import SwiftUI

struct AppHeader: View {
    let title: String
    let subtitle: String?
    let trailingIcon: String?
    let trailingAction: (() -> Void)?
    let style: AppHeaderStyle

    init(
        title: String,
        subtitle: String? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        style: AppHeaderStyle = .opaque
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.style = style
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: TFSpacing.xs) {
                    Text(title)
                        .font(TFFont.title1)
                        .foregroundStyle(Color.tfTextPrimary)
                        .accessibilityAddTraits(.isHeader)

                    if let subtitle {
                        Text(subtitle)
                            .font(TFFont.caption)
                            .foregroundStyle(Color.tfTextSecondary)
                    }
                }

                Spacer()

                if let trailingIcon, let trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingIcon)
                            .font(.system(size: 24))
                            .foregroundStyle(Color.tfTextSecondary)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, TFSpacing.md)
            .padding(.top, TFSpacing.sm)
            .padding(.bottom, TFSpacing.sm)

            if style == .opaque {
                Rectangle()
                    .fill(TFColor.borderSubtle)
                    .frame(height: 0.5)
            }
        }
        .background(style == .opaque ? Color.tfBackground : Color.clear)
    }
}

#Preview("Opaque") {
    VStack {
        AppHeader(
            title: "My Finds",
            subtitle: "24 items",
            trailingIcon: "person.circle",
            trailingAction: {},
            style: .opaque
        )
        Spacer()
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Transparent") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            AppHeader(
                title: "Scan",
                trailingIcon: "bolt.fill",
                trailingAction: {},
                style: .transparent
            )
            Spacer()
        }
    }
}
