import SwiftUI

/// Golden banner overlay for Chronarch-level achievement announcements.
/// Slides down from top and auto-dismisses after 5 seconds.
struct AnnouncementBannerView: View {
    @Environment(AnnouncementManager.self) private var announcements

    var body: some View {
        if let announcement = announcements.activeAnnouncement {
            VStack(spacing: 0) {
                bannerContent(announcement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Spacer()
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: announcement.id)
        }
    }

    private func bannerContent(_ announcement: AnnouncementManager.Announcement) -> some View {
        HStack(spacing: 10) {
            // Chronarch icon
            Image(systemName: "bolt.ring.closed")
                .font(.title3.weight(.bold))
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                // Player name with full VIP styling
                HStack(spacing: 4) {
                    VIPNameView(
                        name: announcement.playerName,
                        vipTier: announcement.vipTier,
                        nameColorId: announcement.nameColorId,
                        title: nil,
                        showBadge: false,
                        font: .subheadline.weight(.bold)
                    )

                    if let title = announcement.title {
                        Text(title)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.yellow.opacity(0.8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.yellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(announcement.message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Button {
                announcements.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Dark base
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.85))

                // Golden border glow
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.yellow, .orange, .yellow.opacity(0.5), .orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )

                // Subtle golden shimmer
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.08), .clear, .orange.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}
