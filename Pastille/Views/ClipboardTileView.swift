import SwiftUI
import AppKit

struct ClipboardTileView: View {
    let item: HistoryItem
    let index: Int
    @Bindable var appState: AppState

    private var isSelected: Bool { index == appState.selectedIndex }

    private var contentType: ContentKind {
        let types = Set(item.contents.map(\.type))
        if types.contains(NSPasteboard.PasteboardType.png.rawValue)
            || types.contains(NSPasteboard.PasteboardType.tiff.rawValue) {
            return .image
        }
        if types.contains(NSPasteboard.PasteboardType.fileURL.rawValue) {
            return .file
        }
        return .text
    }

    private enum ContentKind {
        case text, image, file
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // App icon and name
            HStack(spacing: 5) {
                if let bundleId = item.bundleIdentifier,
                   let icon = AppIconCache.shared.icon(for: bundleId) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 21, height: 21)
                }
                Text(item.appName ?? "Unknown")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Content preview
            Group {
                switch contentType {
                case .text:
                    Text(item.plainTextPreview ?? "")
                        .font(.system(size: 16))
                        .lineLimit(5)
                        .foregroundStyle(.primary)

                case .image:
                    imagePreview
                        .frame(maxWidth: .infinity, alignment: .center)

                case .file:
                    filePreview
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Spacer(minLength: 0)

            // Timestamp
            Text(item.timestamp, style: .relative)
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(width: 232, height: 204)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }

    @ViewBuilder
    private var imagePreview: some View {
        let imageData = item.contents
            .first(where: {
                $0.type == NSPasteboard.PasteboardType.png.rawValue
                || $0.type == NSPasteboard.PasteboardType.tiff.rawValue
            })?.value

        if let data = imageData, let thumbnail = PreviewGenerator.imageThumbnail(data) {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var filePreview: some View {
        let fileURLString = item.contents
            .first(where: { $0.type == NSPasteboard.PasteboardType.fileURL.rawValue })
            .flatMap { $0.value }
            .flatMap { String(data: $0, encoding: .utf8) }

        if let urlString = fileURLString, let url = URL(string: urlString) {
            Label(url.lastPathComponent, systemImage: "doc")
                .font(.system(size: 16))
                .lineLimit(2)
        } else {
            Label("File", systemImage: "doc")
                .font(.system(size: 16))
        }
    }
}
