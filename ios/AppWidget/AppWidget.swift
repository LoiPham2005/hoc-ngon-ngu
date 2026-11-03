import SwiftUI
import WidgetKit

// Widget màn hình chính + màn khoá. Dữ liệu do Flutter ghi (HomeWidgetService, lib/modules/home_widget)
// vào UserDefaults của App Group; khoá phải khớp `buildHomeWidgetData`.

private let homeURL = URL(string: "lingua://widget/home?homeWidget")!
private let reviewURL = URL(string: "lingua://widget/review?homeWidget")!

// MARK: - Màu (AppPalette, màu chủ đạo mặc định indigo)

private extension Color {
  init(light: UInt32, dark: UInt32) {
    self.init(
      UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
  }

  static let brand = Color(light: 0x5B5BD6, dark: 0x9C9CFF)
  static let streak = Color(light: 0xFF8A00, dark: 0xFF8A00)
  static let surface = Color(light: 0xFFFFFF, dark: 0x181B25)
  static let track = Color(light: 0xEEF0F6, dark: 0x232735)
  static let text = Color(light: 0x181B29, dark: 0xF0F1F6)
  static let muted = Color(light: 0x6A6F86, dark: 0x9CA1B8)
}

private extension UIColor {
  convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
  }
}

// MARK: - Dữ liệu

struct LearnerEntry: TimelineEntry {
  let date: Date
  var streak = 0
  var today = 0
  var goal = 10
  var due = 0
  var courseFlag = "🇯🇵"
  var continueTitle = "Hiragana"
  /// Lượt học 7 ngày kết thúc hôm nay (cũ → mới) + chữ viết tắt thứ tương ứng.
  var bars = [Int](repeating: 0, count: 7)
  var weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
  var labelStreak = "ngày liên tiếp"
  var labelToday = "Hôm nay"
  var labelDue = "Không có mục cần ôn"
  var labelContinue = "Học tiếp"

  var progress: Double { goal <= 0 ? 0 : min(Double(today) / Double(goal), 1) }

  static let sample = LearnerEntry(
    date: Date(), streak: 5, today: 6, due: 12, bars: [4, 10, 0, 8, 12, 3, 6])

  /// Ngày học gần nhất không phải hôm nay → lượt hôm nay = 0; cũ hơn hôm qua → chuỗi = 0.
  static func load(now: Date = Date()) -> LearnerEntry {
    var entry = LearnerEntry(date: now)
    let groupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String
    guard let defaults = UserDefaults(suiteName: groupId), defaults.object(forKey: "streak") != nil
    else { return entry.withWeekdays(nil, now: now) }

    let calendar = Calendar.current
    let today = dayKey(now)
    let yesterday = dayKey(calendar.date(byAdding: .day, value: -1, to: now)!)
    let last = defaults.string(forKey: "lastActiveDay") ?? ""
    entry.streak = last == today || last == yesterday ? defaults.integer(forKey: "streak") : 0
    entry.today = last == today ? defaults.integer(forKey: "todayCount") : 0
    entry.goal = max(defaults.integer(forKey: "dailyGoal"), 1)
    entry.due = defaults.integer(forKey: "dueCount")
    entry.courseFlag = defaults.string(forKey: "courseFlag") ?? entry.courseFlag
    entry.continueTitle = defaults.string(forKey: "continueTitle") ?? entry.continueTitle
    entry.labelStreak = defaults.string(forKey: "labelStreak") ?? entry.labelStreak
    entry.labelToday = defaults.string(forKey: "labelToday") ?? entry.labelToday
    entry.labelDue = defaults.string(forKey: "labelDue") ?? entry.labelDue
    entry.labelContinue = defaults.string(forKey: "labelContinue") ?? entry.labelContinue

    // last7 kết thúc ở last7End (ngày app ghi) → dời về 7 ngày kết thúc hôm nay.
    let values = (defaults.string(forKey: "last7") ?? "").split(separator: ",").map {
      Int($0) ?? 0
    }
    if values.count == 7, let end = parseDay(defaults.string(forKey: "last7End")) {
      let startOfToday = calendar.startOfDay(for: now)
      let lag = calendar.dateComponents([.day], from: end, to: startOfToday).day ?? 7
      entry.bars = (0..<7).map { i in
        let index = i + lag
        return index >= 0 && index < 7 ? values[index] : 0
      }
    }
    return entry.withWeekdays(defaults.string(forKey: "labelWeekdays"), now: now)
  }

  private func withWeekdays(_ raw: String?, now: Date) -> LearnerEntry {
    var entry = self
    let names = raw?.split(separator: ",").map(String.init) ?? []
    let mondayFirst = names.count == 7 ? names : weekdays
    let calendar = Calendar.current
    entry.weekdays = (0..<7).map { i in
      let day = calendar.date(byAdding: .day, value: i - 6, to: now)!
      return mondayFirst[(calendar.component(.weekday, from: day) + 5) % 7]
    }
    return entry
  }

  private static let formatter: DateFormatter = {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = .current
    f.dateFormat = "yyyy-MM-dd"
    return f
  }()

  private static func dayKey(_ date: Date) -> String { formatter.string(from: date) }

  private static func parseDay(_ raw: String?) -> Date? {
    raw.flatMap { formatter.date(from: $0) }.map { Calendar.current.startOfDay(for: $0) }
  }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> LearnerEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (LearnerEntry) -> Void) {
    completion(context.isPreview ? .sample : .load())
  }

  /// Vẽ lại lúc nửa đêm để lượt hôm nay / chuỗi ngày tự tính lại khi sang ngày mới.
  func getTimeline(in context: Context, completion: @escaping (Timeline<LearnerEntry>) -> Void) {
    let now = Date()
    let midnight = Calendar.current.nextDate(
      after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)
      ?? now.addingTimeInterval(3600)
    completion(Timeline(entries: [.load(now: now)], policy: .after(midnight)))
  }
}

// MARK: - Thành phần

private struct StreakBlock: View {
  let entry: LearnerEntry
  var size: CGFloat = 34

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("🔥").font(.system(size: size * 0.7))
      Text("\(entry.streak)")
        .font(.system(size: size, weight: .bold, design: .rounded))
        .foregroundColor(entry.streak > 0 ? .streak : .muted)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
      Text(entry.labelStreak).font(.caption).foregroundColor(.muted).lineLimit(2)
    }
  }
}

private struct GoalRing: View {
  let entry: LearnerEntry

  var body: some View {
    ZStack {
      Circle().stroke(Color.track, lineWidth: 6)
      Circle()
        .trim(from: 0, to: entry.progress)
        .stroke(Color.brand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(entry.today)/\(entry.goal)")
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundColor(.text)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .padding(4)
    }
    .frame(width: 50, height: 50)
  }
}

private struct GoalBar: View {
  let progress: Double

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.track)
        Capsule().fill(Color.brand).frame(width: max(geo.size.width * progress, 6))
      }
    }
    .frame(height: 8)
  }
}

private struct SummaryColumn: View {
  let entry: LearnerEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(entry.labelToday).font(.caption).foregroundColor(.muted)
        Spacer()
        Text("\(entry.today)/\(entry.goal)")
          .font(.system(.caption, design: .rounded).weight(.semibold))
          .foregroundColor(.text)
      }
      GoalBar(progress: entry.progress)
      Link(destination: entry.due > 0 ? reviewURL : homeURL) {
        Label(entry.labelDue, systemImage: "arrow.triangle.2.circlepath")
          .font(.caption)
          .foregroundColor(entry.due > 0 ? .brand : .muted)
          .lineLimit(1)
      }
      HStack(spacing: 4) {
        Text(entry.courseFlag)
        Text("\(entry.labelContinue): \(entry.continueTitle)")
          .foregroundColor(.text)
          .lineLimit(1)
      }
      .font(.caption)
    }
  }
}

private struct WeekChart: View {
  let entry: LearnerEntry

  var body: some View {
    let peak = max(entry.bars.max() ?? 0, 1)
    HStack(alignment: .bottom, spacing: 8) {
      ForEach(0..<7, id: \.self) { i in
        VStack(spacing: 4) {
          GeometryReader { geo in
            VStack {
              Spacer(minLength: 0)
              RoundedRectangle(cornerRadius: 4)
                .fill(i == 6 ? Color.brand : Color.brand.opacity(0.35))
                .frame(height: max(geo.size.height * CGFloat(entry.bars[i]) / CGFloat(peak), 4))
            }
          }
          Text(entry.weekdays[i])
            .font(.system(size: 10, weight: i == 6 ? .bold : .regular))
            .foregroundColor(i == 6 ? .text : .muted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
      }
    }
  }
}

// MARK: - Theo kích thước

struct LinguaWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: LearnerEntry

  var body: some View {
    content.widgetURL(homeURL)
  }

  @ViewBuilder private var content: some View {
    switch family {
    case .systemSmall:
      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          StreakBlock(entry: entry, size: 30)
          Spacer(minLength: 0)
        }
        Spacer(minLength: 4)
        HStack {
          Spacer()
          GoalRing(entry: entry)
        }
      }
      .widgetBackground(.surface)
    case .systemMedium:
      HStack(spacing: 16) {
        StreakBlock(entry: entry).frame(width: 96, alignment: .leading)
        SummaryColumn(entry: entry)
      }
      .widgetBackground(.surface)
    case .systemLarge:
      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top, spacing: 16) {
          StreakBlock(entry: entry).frame(width: 96, alignment: .leading)
          SummaryColumn(entry: entry)
        }
        WeekChart(entry: entry)
      }
      .widgetBackground(.surface)
    default:
      if #available(iOSApplicationExtension 16.0, *) {
        AccessoryView(entry: entry)
      }
    }
  }
}

@available(iOSApplicationExtension 16.0, *)
private struct AccessoryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: LearnerEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      Gauge(value: entry.progress) {
        Text("🔥")
      } currentValueLabel: {
        Text("\(entry.streak)")
      }
      .gaugeStyle(.accessoryCircular)
      .widgetBackground(.clear, padded: false)
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 2) {
        Text("🔥 \(entry.streak) \(entry.labelStreak)").font(.headline).lineLimit(1)
        Text("\(entry.labelToday) \(entry.today)/\(entry.goal)").font(.caption)
        ProgressView(value: entry.progress)
      }
      .widgetBackground(.clear, padded: false)
    default:
      Text("🔥 \(entry.streak) · \(entry.today)/\(entry.goal)")
        .widgetBackground(.clear, padded: false)
    }
  }
}

private extension View {
  /// iOS 17+: `containerBackground` (hệ thống tự chừa lề); cũ hơn: tự tô nền + padding.
  @ViewBuilder func widgetBackground(_ color: Color, padded: Bool = true) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(color, for: .widget)
    } else if padded {
      frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(color)
    } else {
      self
    }
  }
}

// MARK: - Widget

struct LinguaWidget: Widget {
  let kind = "AppWidget"

  private var families: [WidgetFamily] {
    var list: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
    if #available(iOSApplicationExtension 16.0, *) {
      list += [.accessoryCircular, .accessoryRectangular, .accessoryInline]
    }
    return list
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      LinguaWidgetView(entry: entry)
    }
    .configurationDisplayName(PickerText.name)
    .description(PickerText.description)
    .supportedFamilies(families)
  }
}

/// Chữ ở màn chọn widget — theo ngôn ngữ máy (app chưa kịp gửi nhãn).
private enum PickerText {
  private static let language = Locale.preferredLanguages.first?.prefix(2) ?? "en"

  static var name: String {
    switch language {
    case "vi": return "Chuỗi ngày học"
    case "ja": return "連続学習"
    default: return "Study streak"
    }
  }

  static var description: String {
    switch language {
    case "vi": return "Chuỗi ngày, mục tiêu hôm nay và mục cần ôn."
    case "ja": return "連続日数・今日の目標・復習を表示します。"
    default: return "Your streak, today's goal and items to review."
    }
  }
}

@main
struct AppWidgetBundle: WidgetBundle {
  var body: some Widget {
    LinguaWidget()
  }
}
