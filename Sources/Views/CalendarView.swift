import SwiftUI
import SwiftData

/// Month view of every warranty end date. The list screens answer "what do I
/// own", this one answers "what runs out this month", which is the question
/// people actually ask when they are about to lose a guarantee.
struct CalendarView: View {
    @Query(sort: \GearItem.warrantyEnd) private var items: [GearItem]

    @State private var month = Calendar.current.startOfMonth(for: .now)
    @State private var selected: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    weekdayRow
                    grid
                    dayList
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Warranty calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        month = calendar.startOfMonth(for: .now)
                        selected = nil
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                shift(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(month, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.semibold))
            Spacer()
            Button {
                shift(1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .padding(.top, 8)
    }

    private var weekdayRow: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let hits = items(on: day)
        let isToday = calendar.isDateInToday(day)
        let isSelected = selected.map { calendar.isDate($0, inSameDayAs: day) } ?? false

        return Button {
            selected = day
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.callout)
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().fill(isToday ? Color.blue : Color.clear)
                    )
                HStack(spacing: 3) {
                    ForEach(hits.prefix(3), id: \.persistentModelID) { item in
                        Circle()
                            .fill(dotColor(for: item))
                            .frame(width: 5, height: 5)
                    }
                    if hits.isEmpty { Color.clear.frame(width: 5, height: 5) }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var dayList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let selected {
                let hits = items(on: selected)
                Text(selected, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
                if hits.isEmpty {
                    Text("Nothing expires on this day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(hits, id: \.persistentModelID) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.itemCategory.symbol)
                                .foregroundStyle(dotColor(for: item))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline.weight(.semibold))
                                Text(item.statusText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("Tap a day to see what expires then.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func items(on day: Date) -> [GearItem] {
        items.filter { calendar.isDate($0.warrantyEnd, inSameDayAs: day) }
    }

    private func dotColor(for item: GearItem) -> Color {
        switch item.warrantyState {
        case .active: return .green
        case .endingSoon: return .orange
        case .expired: return .red
        }
    }

    private func shift(_ months: Int) {
        if let moved = calendar.date(byAdding: .month, value: months, to: month) {
            month = moved
            selected = nil
        }
    }

    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            result.append(calendar.date(byAdding: .day, value: offset, to: first))
        }
        return result
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
