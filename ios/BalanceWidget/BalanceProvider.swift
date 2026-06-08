import WidgetKit
import SwiftUI

struct BalanceEntry: TimelineEntry {
    let date: Date
    let totalBalance: Double
    let providerCount: Int
    let lastUpdated: Date?
    let currency: String
}

struct BalanceProvider: TimelineProvider {
    let appGroup = "group.com.jphermans.ai-balance-tracker"
    
    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(
            date: Date(),
            totalBalance: 45.12,
            providerCount: 3,
            lastUpdated: Date(),
            currency: "USD"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadEntry() -> BalanceEntry {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return BalanceEntry(date: Date(), totalBalance: 0, providerCount: 0, lastUpdated: nil, currency: "USD")
        }
        let balance = defaults.double(forKey: "widget_total_balance")
        let count = defaults.integer(forKey: "widget_provider_count")
        let currency = defaults.string(forKey: "widget_currency") ?? "USD"
        let timestamp = defaults.double(forKey: "widget_last_updated")
        let lastUpdated = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        
        return BalanceEntry(
            date: Date(),
            totalBalance: balance,
            providerCount: count,
            lastUpdated: lastUpdated,
            currency: currency
        )
    }
}
