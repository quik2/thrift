import SwiftUI

struct AppHeader: View {
    let title: String
    let subtitle: String?
    let trailingIcon: String?
    let trailingAction: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
    }

    var body: some View {
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
                        .font(.system(size: 22))
                        .foregroundStyle(Color.tfTextSecondary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, TFSpacing.md)
        .padding(.top, TFSpacing.sm)
        .padding(.bottom, TFSpacing.sm)
    }
}

#Preview {
    VStack {
        AppHeader(
            title: "My Finds",
            subtitle: "24 items · $2,847 value",
            trailingIcon: "person.circle",
            trailingAction: {}
        )
        Spacer()
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
