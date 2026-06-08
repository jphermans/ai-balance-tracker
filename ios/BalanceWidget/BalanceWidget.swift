import SwiftUI
import WidgetKit

struct BalanceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    var entry: BalanceProvider.Entry
    
    private var bgColor: Color {
        colorScheme == .dark ? Color(red: 0.04, green: 0.06, blue: 0.14) : Color(red: 0.96, green: 0.96, blue: 0.98)
    }
    private var cardColor: Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.12, blue: 0.22) : .white
    }
    private var accentColor: Color { Color(red: 0.30, green: 0.50, blue: 0.95) }
    private var secondaryText: Color {
        colorScheme == .dark ? Color(white: 0.55) : Color(white: 0.45)
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor)
                    Text("AI Balance")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                    Spacer()
                    if entry.lastUpdated != nil {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundColor(secondaryText)
                    }
                }
                
                Spacer(minLength: 4)
                
                // Balance
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$")
                        .font(.system(size: family == .systemSmall ? 22 : 28, weight: .bold))
                        .foregroundColor(accentColor)
                    Text(String(format: "%.2f", entry.totalBalance))
                        .font(.system(size: family == .systemSmall ? 22 : 28, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 2)
                
                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryText)
                        Text("\(entry.providerCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryText)
                    }
                    Spacer()
                    if let updated = entry.lastUpdated {
                        Text(relativeTime(from: updated))
                            .font(.system(size: 10))
                            .foregroundColor(secondaryText)
                    }
                }
            }
            .padding(family == .systemSmall ? 12 : 16)
        }
    }
    
    private func relativeTime(from date: Date) -> String {
        let interval = -date.timeIntervalSinceNow
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceProvider()) { entry in
            BalanceWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("AI Balance")
        .description("See your total AI provider balance at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
