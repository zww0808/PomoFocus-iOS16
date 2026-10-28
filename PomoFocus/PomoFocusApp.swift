import SwiftUI
import UserNotifications

@main
struct PomoFocusApp: App {
    @StateObject private var model = TimerModel()
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(model)
                .preferredColorScheme(.dark)
        }
    }
}

struct FocusRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var minutes: Int
}

enum FocusMode: String, CaseIterable, Identifiable {
    case focus = "专注", shortBreak = "短休息", longBreak = "长休息"
    var id: String { rawValue }
    var symbol: String { self == .focus ? "brain.head.profile" : (self == .shortBreak ? "cup.and.saucer.fill" : "moon.stars.fill") }
}

final class TimerModel: ObservableObject {
    @Published var mode: FocusMode = .focus
    @Published var focusMinutes: Int = 25 { didSet { saveSettings(); resetIfIdle() } }
    @Published var shortMinutes: Int = 5 { didSet { saveSettings(); resetIfIdle() } }
    @Published var longMinutes: Int = 15 { didSet { saveSettings(); resetIfIdle() } }
    @Published var longEvery: Int = 4 { didSet { saveSettings() } }
    @Published var completedCount: Int = 0
    @Published var records: [FocusRecord] = []
    @Published var remaining: TimeInterval = 25 * 60
    @Published var running = false
    @Published var notificationEnabled = true { didSet { saveSettings() } }
    @Published var autoAdvance = false { didSet { saveSettings() } }
    @Published var soundEnabled = true { didSet { saveSettings() } }
    private var deadline: Date?
    private var ticker: Timer?
    private let defaults = UserDefaults.standard
    private let notificationID = "pomofocus.timer.end"

    init() {
        let d = defaults
        focusMinutes = d.object(forKey: "focusMinutes") as? Int ?? 25
        shortMinutes = d.object(forKey: "shortMinutes") as? Int ?? 5
        longMinutes = d.object(forKey: "longMinutes") as? Int ?? 15
        longEvery = d.object(forKey: "longEvery") as? Int ?? 4
        notificationEnabled = d.object(forKey: "notificationEnabled") as? Bool ?? true
        autoAdvance = d.bool(forKey: "autoAdvance")
        soundEnabled = d.object(forKey: "soundEnabled") as? Bool ?? true
        if let bytes = d.data(forKey: "records"), let saved = try? JSONDecoder().decode([FocusRecord].self, from: bytes) { records = saved }
        completedCount = d.integer(forKey: "completedCount")
        remaining = Double(focusMinutes * 60)
        if let modeString = d.string(forKey: "currentMode"), let restoredMode = FocusMode(rawValue: modeString) { mode = restoredMode }
        if let time = d.object(forKey: "deadline") as? Date, time > Date() {
            deadline = time
            running = true
            remaining = time.timeIntervalSinceNow
            scheduleTicker()
        } else if let time = d.object(forKey: "deadline") as? Date {
            // Recover an elapsed session after termination.
            deadline = time
            running = true
            complete()
        } else if let paused = d.object(forKey: "remaining") as? Double {
            remaining = max(1, paused)
        } else { remaining = duration(for: mode) }
    }
    private func saveSettings() {
        defaults.set(focusMinutes, forKey: "focusMinutes")
        defaults.set(shortMinutes, forKey: "shortMinutes")
        defaults.set(longMinutes, forKey: "longMinutes")
        defaults.set(longEvery, forKey: "longEvery")
        defaults.set(notificationEnabled, forKey: "notificationEnabled")
        defaults.set(autoAdvance, forKey: "autoAdvance")
        defaults.set(soundEnabled, forKey: "soundEnabled")
    }
    func duration(for mode: FocusMode) -> TimeInterval {
        Double((mode == .focus ? focusMinutes : mode == .shortBreak ? shortMinutes : longMinutes) * 60)
    }
    private func resetIfIdle() { if !running && deadline == nil { remaining = duration(for: mode); persistState() } }
    func select(_ newMode: FocusMode) { stop(); mode = newMode; remaining = duration(for: newMode); persistState() }
    func toggle() { running ? pause() : start() }
    func start() {
        guard !running else { return }
        if remaining <= 0 { remaining = duration(for: mode) }
        running = true
        deadline = Date().addingTimeInterval(remaining)
        persistState()
        scheduleTicker()
        requestAndScheduleNotification()
    }
    func pause() {
        if let deadline { remaining = max(0, deadline.timeIntervalSinceNow) }
        running = false
        deadline = nil
        ticker?.invalidate(); ticker = nil
        cancelNotification()
        persistState()
    }
    func stop() {
        running = false; deadline = nil
        ticker?.invalidate(); ticker = nil
        cancelNotification(); persistState()
    }
    func reset() { stop(); remaining = duration(for: mode); persistState() }
    func skip() { let next = mode == .focus ? restMode() : FocusMode.focus; select(next); if autoAdvance { start() } }
    private func restMode() -> FocusMode { ((completedCount + 1) % max(1, longEvery) == 0) ? .longBreak : .shortBreak }
    private func scheduleTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.tick() }
        if let ticker { RunLoop.main.add(ticker, forMode: .common) }
    }
    func tick() {
        guard running, let deadline else { return }
        remaining = max(0, deadline.timeIntervalSinceNow)
        if remaining <= 0 { complete() }
    }
    private func complete() {
        let wasFocus = mode == .focus
        let nextRest = restMode()
        stop()
        if wasFocus {
            records.insert(FocusRecord(date: Date(), minutes: focusMinutes), at: 0)
            completedCount += 1
            if records.count > 1000 { records = Array(records.prefix(1000)) }
            defaults.set(try? JSONEncoder().encode(records), forKey: "records")
            defaults.set(completedCount, forKey: "completedCount")
        }
        mode = wasFocus ? nextRest : .focus
        remaining = duration(for: mode)
        persistState()
        if autoAdvance { start() }
    }
    private func persistState() {
        defaults.set(mode.rawValue, forKey: "currentMode")
        defaults.set(deadline, forKey: "deadline")
        defaults.set(remaining, forKey: "remaining")
    }
    private func cancelNotification() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID]) }
    private func requestAndScheduleNotification() {
        cancelNotification()
        guard notificationEnabled, remaining > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] allowed, _ in
            guard allowed else { return }
            DispatchQueue.main.async { self?.scheduleEndNotification() }
        }
    }
    private func scheduleEndNotification() {
        guard running, notificationEnabled, let deadline else { return }
        let seconds = deadline.timeIntervalSinceNow
        guard seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = mode == .focus ? "专注完成！" : "休息结束！"
        content.body = mode == .focus ? "做得好，休息一下吧。" : "准备好开始下一轮专注了吗？"
        if soundEnabled { content.sound = .default }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger))
    }
    var todayMinutes: Int { let calendar = Calendar.current; return records.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.minutes } }
    var todaySessions: Int { records.filter { Calendar.current.isDateInToday($0.date) }.count }
    var weekMinutes: Int { records.filter { $0.date >= Calendar.current.startOfDay(for: Date().addingTimeInterval(-6 * 86400)) }.reduce(0) { $0 + $1.minutes } }
    func dayMinutes(daysAgo: Int) -> Int { let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date(); return records.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.minutes } }
    func clearHistory() { records = []; completedCount = 0; defaults.removeObject(forKey: "records"); defaults.set(0, forKey: "completedCount") }
}
