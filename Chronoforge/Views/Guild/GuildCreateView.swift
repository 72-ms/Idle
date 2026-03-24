import SwiftUI

struct GuildCreateView: View {
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var guildName = ""
    @State private var guildDescription = ""
    @State private var selectedEmblem = "emblem_default"
    @State private var primaryColor = "blue"
    @State private var secondaryColor = "gold"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.cyan.opacity(0.08))
                                .frame(width: 80, height: 80)
                            Image(systemName: "shield.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.cyan)
                        }

                        Text(guildName.isEmpty ? "Your Guild" : guildName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Guild Name")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))

                        TextField("Enter name...", text: $guildName)
                            .font(.subheadline)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))

                        TextField("What's your guild about?", text: $guildDescription, axis: .vertical)
                            .font(.subheadline)
                            .lineLimit(3...5)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Emblem picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Emblem")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(GuildBanner.emblemOptions, id: \.self) { emblem in
                                Button {
                                    selectedEmblem = emblem
                                } label: {
                                    Image(systemName: emblemIcon(emblem))
                                        .font(.title3)
                                        .foregroundStyle(selectedEmblem == emblem ? .cyan : .white.opacity(0.4))
                                        .frame(width: 50, height: 50)
                                        .background(selectedEmblem == emblem ? Color.cyan.opacity(0.1) : Color.white.opacity(0.03))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(selectedEmblem == emblem ? .cyan : .clear, lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                    }

                    // Colors
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Colors")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))

                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text("Primary").font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
                                colorPicker(selected: $primaryColor)
                            }
                            VStack(spacing: 4) {
                                Text("Secondary").font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
                                colorPicker(selected: $secondaryColor)
                            }
                        }
                    }

                    // Create button
                    Button {
                        createGuild()
                    } label: {
                        Text("Create Guild")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(guildName.trimmingCharacters(in: .whitespaces).count < 3)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Create Guild")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func createGuild() {
        let banner = GuildBanner(
            emblemId: selectedEmblem,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor
        )
        _ = guildManager.createGuild(
            name: guildName.trimmingCharacters(in: .whitespaces),
            description: guildDescription.trimmingCharacters(in: .whitespaces),
            banner: banner,
            player: player,
            vipTier: store.vipProgress.currentTier
        )
        dismiss()
    }

    private func colorPicker(selected: Binding<String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(GuildBanner.colorOptions, id: \.self) { color in
                    Button {
                        selected.wrappedValue = color
                    } label: {
                        Circle()
                            .fill(bannerColor(color))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().strokeBorder(selected.wrappedValue == color ? .white : .clear, lineWidth: 2)
                            )
                    }
                }
            }
        }
    }

    private func bannerColor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "gold": return .yellow
        case "purple": return .purple
        case "silver": return Color(white: 0.75)
        case "orange": return .orange
        case "cyan": return .cyan
        case "pink": return .pink
        case "black": return Color(white: 0.15)
        case "white": return .white
        case "crimson": return Color(red: 0.86, green: 0.08, blue: 0.24)
        default: return .gray
        }
    }

    private func emblemIcon(_ emblem: String) -> String {
        switch emblem {
        case "emblem_sword": return "bolt.fill"
        case "emblem_shield": return "shield.fill"
        case "emblem_crown": return "crown.fill"
        case "emblem_flame": return "flame.fill"
        case "emblem_star": return "star.fill"
        case "emblem_gear": return "gearshape.fill"
        case "emblem_crystal": return "diamond.fill"
        case "emblem_dragon": return "lizard.fill"
        case "emblem_phoenix": return "bird.fill"
        case "emblem_wolf": return "pawprint.fill"
        case "emblem_serpent": return "tornado"
        case "emblem_tower": return "building.columns.fill"
        case "emblem_hourglass": return "hourglass"
        case "emblem_infinity": return "infinity"
        case "emblem_void": return "circle.dashed"
        default: return "shield.lefthalf.filled"
        }
    }
}
