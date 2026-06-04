import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String?
    let systemImage: String?
    let content: Content
    
    init(title: String? = nil, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || systemImage != nil {
                HStack(spacing: 8) {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .foregroundColor(.accentColor)
                    }
                    if let title = title {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondarySystemGroupedBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}
