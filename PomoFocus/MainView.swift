import SwiftUI

private let accent = Color(red: 1, green: 0.43, blue: 0.24)
private let panel = Color(red: 0.13, green: 0.15, blue: 0.19)

struct MainView: View {
    @EnvironmentObject var model: TimerModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            TimerScreen().tabItem { Label("计时", systemImage: "timer") }.tag(0)
            StatisticsScreen().tabItem { Label("统计", systemImage: "chart.bar.fill") }.tag(1)
            SettingsScreen().tabItem { Label("设置", systemImage: "gearshape.fill") }.tag(2)
        }
        .tint(accent)
        .onChange(of: scenePhase) { newPhase in if newPhase == .active { model.tick() } }
    }
}

struct TimerScreen: View {
    @EnvironmentObject var model: TimerModel
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 28) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("POMO / FOCUS").font(.system(size: 12, weight: .bold, design: .rounded)).tracking(3).foregroundStyle(accent)
                            Text("专注此刻").font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Image(systemName: "flame.fill").font(.system(size: 24)).foregroundStyle(accent)
                    }.padding(.top, 25)
                    HStack(spacing: 6) {
                        ForEach(FocusMode.allCases) { mode in
                            Button { model.select(mode) } label: {
                                HStack(spacing: 5) { Image(systemName: mode.symbol); Text(mode.rawValue) }
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                                    .background(model.mode == mode ? accent : panel, in: RoundedRectangle(cornerRadius: 13))
                                    .foregroundStyle(model.mode == mode ? Color.black : Color.white.opacity(0.75))
                            }.buttonStyle(.plain)
                        }
                    }
                    ZStack {
                        Circle().stroke(panel, lineWidth: 15)
                        Circle().trim(from: 0, to: max(0, min(1, 1 - model.remaining / max(1, model.duration(for: model.mode)))))
                            .stroke(accent, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90)).animation(.easeInOut(duration: 0.2), value: model.remaining)
                        VStack(spacing: 12) {
                            Text(model.mode.rawValue).font(.subheadline).foregroundStyle(.white.opacity(0.55))
                            Text(clock).font(.system(size: 57, weight: .bold, design: .rounded)).monospacedDigit()
                                .minimumScaleFactor(0.6).lineLimit(1)
                            Text(model.running ? "保持节奏，继续加油" : "开始属于你的专注时间")
                                .font(.caption).foregroundStyle(.white.opacity(0.5))
                        }.padding(25)
                    }
                    .frame(width: min(geo.size.width - 72, 300), height: min(geo.size.width - 72, 300))
                    HStack(spacing: 14) {
                        Button { model.reset() } label: { Image(systemName: "arrow.counterclockwise").frame(width: 58, height: 58).background(panel, in: RoundedRectangle(cornerRadius: 18)) }
                            .accessibilityLabel("重置")
                        Button { model.toggle() } label: {
                            HStack(spacing: 10) { Image(systemName: model.running ? "pause.fill" : "play.fill"); Text(model.running ? "暂停" : "开始") }
                                .font(.headline).frame(maxWidth: .infinity).frame(height: 58).foregroundStyle(.black)
                                .background(accent, in: RoundedRectangle(cornerRadius: 18))
                        }
                        Button { model.skip() } label: { Image(systemName: "forward.end.fill").frame(width: 58, height: 58).background(panel, in: RoundedRectangle(cornerRadius: 18)) }
                            .accessibilityLabel("跳过")
                    }.buttonStyle(.plain)
                    HStack(spacing: 12) {
                        MiniStat(title: "今日专注", value: "\(model.todayMinutes) 分钟", symbol: "clock.fill")
                        MiniStat(title: "完成番茄", value: "\(model.todaySessions) 个", symbol: "checkmark.circle.fill")
                    }
                    Spacer(minLength: 12)
                }.padding(.horizontal, 24).frame(maxWidth: 580)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    private var clock: String {
        let seconds = max(0, Int(ceil(model.remaining)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct MiniStat: View {
    let title: String; let value: String; let symbol: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.caption).foregroundStyle(.white.opacity(0.5))
                Text(value).font(.system(size: 16, weight: .bold, design: .rounded))
            }
            Spacer(minLength: 0)
        }.padding(16).frame(maxWidth: .infinity).background(panel, in: RoundedRectangle(cornerRadius: 17))
    }
}

struct StatisticsScreen: View {
    @EnvironmentObject var model: TimerModel
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 12) {
                        MiniStat(title: "今日分钟", value: "\(model.todayMinutes)", symbol: "sun.max.fill")
                        MiniStat(title: "近7日分钟", value: "\(model.weekMinutes)", symbol: "chart.bar.fill")
                    }
                    VStack(alignment: .leading, spacing: 15) {
                        Text("最近 7 天").font(.title3.bold())
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach((0..<7).reversed(), id: \.self) { daysAgo in
                                VStack(spacing: 8) {
                                    Text("\(model.dayMinutes(daysAgo: daysAgo))").font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                                    RoundedRectangle(cornerRadius: 6).fill(accent.opacity(daysAgo == 0 ? 1 : 0.65))
                                        .frame(height: max(5, CGFloat(model.dayMinutes(daysAgo: daysAgo)) / CGFloat(max(25, maxDay)) * 145))
                                    Text(dayLabel(daysAgo)).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
                                }.frame(maxWidth: .infinity)
                            }
                        }.frame(height: 195, alignment: .bottom)
                    }.padding(20).background(panel, in: RoundedRectangle(cornerRadius: 18))
                    VStack(alignment: .leading, spacing: 12) {
                        Text("近期专注记录").font(.title3.bold())
                        if model.records.isEmpty { Text("还没有记录，开始第一个番茄钟吧！").font(.subheadline).foregroundStyle(.white.opacity(0.55)).padding(.vertical, 16) }
                        ForEach(model.records.prefix(30)) { record in
                            HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(accent); Text(record.date, format: .dateTime.month().day().hour().minute()); Spacer(); Text("\(record.minutes) 分钟").foregroundStyle(.white.opacity(0.7)) }
                                .font(.subheadline).padding(.vertical, 7)
                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }.padding(20).background(panel, in: RoundedRectangle(cornerRadius: 18))
                }.padding(20)
            }.navigationTitle("专注统计")
        }.navigationViewStyle(.stack)
    }
    private var maxDay: Int { (0..<7).map { model.dayMinutes(daysAgo: $0) }.max() ?? 25 }
    private func dayLabel(_ daysAgo: Int) -> String { let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date(); return DateFormatter.localizedString(from: day, dateStyle: .short, timeStyle: .none).components(separatedBy: "/").last ?? "" }
}

struct SettingsScreen: View {
    @EnvironmentObject var model: TimerModel
    @State private var clearAlert = false
    var body: some View {
        NavigationView {
            Form {
                Section("计时设置 · 分钟") {
                    Stepper("专注时长：\(model.focusMinutes)", value: $model.focusMinutes, in: 1...120, step: 1)
                    Stepper("短休息：\(model.shortMinutes)", value: $model.shortMinutes, in: 1...60)
                    Stepper("长休息：\(model.longMinutes)", value: $model.longMinutes, in: 1...90)
                    Stepper("每 \(model.longEvery) 个番茄后长休息", value: $model.longEvery, in: 2...10)
                    Text("修改当前模式时长后，请点击计时页的重置按钮以应用。").font(.caption).foregroundStyle(.secondary)
                }
                Section("提醒与自动化") {
                    Toggle("结束时发送通知", isOn: $model.notificationEnabled).tint(accent)
                    Toggle("通知声音", isOn: $model.soundEnabled).tint(accent)
                    Toggle("自动进入下一阶段", isOn: $model.autoAdvance).tint(accent)
                    Text("计时采用绝对结束时间，锁屏或切换应用后仍可计算剩余时间。通知需要系统授权；iOS 不保证后台持续执行代码。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("数据") {
                    Button(role: .destructive) { clearAlert = true } label: { Text("清空专注记录") }
                    Text("全部记录仅存储在本机，不联网，不收集个人数据。").font(.caption).foregroundStyle(.secondary)
                }
                Section { HStack { Text("PomoFocus"); Spacer(); Text("1.0 · iOS 16+").foregroundStyle(.secondary) } }
            }
            .navigationTitle("设置")
            .alert("确定清空所有专注记录？", isPresented: $clearAlert) {
                Button("清空", role: .destructive) { model.clearHistory() }
                Button("取消", role: .cancel) { }
            } message: { Text("此操作不可恢复。") }
        }.navigationViewStyle(.stack)
    }
}
