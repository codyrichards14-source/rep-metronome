//
//  ContentView.swift
//  rep metronome
//
//  Created by The Richards on 3/29/26.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

private func lockOrientation(_ mask: UIInterfaceOrientationMask) {
    OrientationLock.shared.mask = mask
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = RepMetroViewModel()

    var body: some View {
        ZStack {
            AppTheme.ink
                .ignoresSafeArea()

            Group {
                switch viewModel.currentScreen {
                case .setup:
                    SetupScreen(viewModel: viewModel)
                        .onAppear { lockOrientation(.portrait) }
                case .active:
                    ActiveScreen(viewModel: viewModel)
                        .onAppear { lockOrientation(.allButUpsideDown) }
                case .rest:
                    RestScreen(viewModel: viewModel)
                        .onAppear { lockOrientation(.portrait) }
                case .log:
                    LogScreen(viewModel: viewModel)
                        .onAppear { lockOrientation(.portrait) }
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))

            if viewModel.showExerciseModal {
                ExerciseModal(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(3)
            }

            if viewModel.showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .zIndex(4)
            }

            ScanlineOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(5)
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.currentScreen)
        .animation(.easeInOut(duration: 0.25), value: viewModel.showExerciseModal)
        .animation(.easeInOut(duration: 0.7), value: viewModel.showSplash)
        .task {
            viewModel.startSplashSequence()
        }
    }
}

private enum AppTheme {
    static let ink = Color(hex: 0x0A0000)
    static let deep = Color(hex: 0x130000)
    static let panel = Color(hex: 0x260006)
    static let card = Color(hex: 0x2E0008)
    static let rim = Color(hex: 0x6A0014)
    static let dust = Color(hex: 0xAA7880)
    static let fog = Color(hex: 0xCFB0B8)
    static let parch = Color(hex: 0xF2E8DF)
    static let blood = Color(hex: 0xC80010)
    static let rose = Color(hex: 0xE8001A)
}

private struct SplashScreen: View {
    @State private var showGlow    = false
    @State private var showIcon    = false
    @State private var showTitle   = false
    @State private var showSub     = false
    @State private var expandLines = false

    var body: some View {
        ZStack {
            // Radial background glow
            RadialGradient(
                colors: [AppTheme.blood.opacity(showGlow ? 0.35 : 0), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.4), value: showGlow)

            VStack(spacing: 0) {
                // Icon with concentric rings
                ZStack {
                    Circle()
                        .stroke(AppTheme.blood.opacity(0.15), lineWidth: 1)
                        .frame(width: 116, height: 116)

                    Circle()
                        .stroke(AppTheme.blood.opacity(0.35), lineWidth: 1)
                        .frame(width: 96, height: 96)

                    Circle()
                        .fill(AppTheme.panel)
                        .frame(width: 76, height: 76)
                        .shadow(color: AppTheme.blood.opacity(0.5), radius: 16)

                    BarbellGlyph()
                        .frame(width: 40, height: 40)
                }
                .scaleEffect(showIcon ? 1.0 : 0.4)
                .opacity(showIcon ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.15), value: showIcon)
                .padding(.bottom, 36)

                // Title — two-tone like setup screen
                HStack(spacing: 0) {
                    Text("REP ")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.parch)
                    Text("METRO")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.blood)
                }
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 16)
                .animation(.easeOut(duration: 0.55).delay(0.5), value: showTitle)

                // Subtitle flanked by expanding lines
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(AppTheme.blood)
                        .frame(width: expandLines ? 48 : 0, height: 1)
                        .animation(.easeOut(duration: 0.7).delay(0.85), value: expandLines)

                    Text("TEMPO TRAINING · GUIDED REPS")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(AppTheme.fog)
                        .opacity(showSub ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.75), value: showSub)
                        .padding(.horizontal, 10)

                    Rectangle()
                        .fill(AppTheme.blood)
                        .frame(width: expandLines ? 48 : 0, height: 1)
                        .animation(.easeOut(duration: 0.7).delay(0.85), value: expandLines)
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.ink.ignoresSafeArea())
        .onAppear {
            showGlow    = true
            showIcon    = true
            showTitle   = true
            showSub     = true
            expandLines = true
        }
    }
}

private struct InfoScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppTheme.ink.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TEMPO TRAINING")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.parch)
                        Text("WHY IT WORKS · HOW TO USE IT")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(4)
                            .foregroundStyle(AppTheme.fog)
                    }
                    .padding(.top, 56)
                    .padding(.bottom, 28)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(AppTheme.rim).frame(height: 1)
                    }

                    // Why tempo training
                    InfoSection(title: "WHY TEMPO TRAINING") {
                        InfoParagraph("Most people focus on what they lift — tempo training focuses on how. By controlling the speed of each phase of a rep, you increase time under tension, the primary driver of muscle growth and strength adaptation.")
                        InfoParagraph("Slowing the eccentric (lowering) phase recruits more muscle fibers and causes greater mechanical stress than simply dropping the weight. Research consistently shows controlled eccentrics produce superior hypertrophy compared to free-tempo lifting.")
                        InfoParagraph("Tempo training also builds body awareness. When you're forced to own every inch of a movement, you identify weak points, improve joint stability, and reduce injury risk.")
                    }

                    // Eccentric / Concentric
                    InfoSection(title: "THE TWO PHASES") {
                        InfoRow(label: "ECCENTRIC", detail: "The lowering or lengthening phase. Example: descending into a squat, lowering a barbell during a bench press, or the down phase of a curl. This is where the most muscle damage — and growth stimulus — occurs.")
                        InfoRow(label: "CONCENTRIC", detail: "The lifting or contracting phase. Example: driving out of the squat, pressing the bar up, or curling the weight up. Keep this phase controlled — don't use momentum.")
                    }

                    // Features
                    InfoSection(title: "APP FEATURES") {
                        InfoRow(label: "AUDIO CUES", detail: "The app calls each rep number, then cues \"Down\" and \"Up\" in sync with your tempo. You never need to watch the screen — keep your eyes on your form.")
                        InfoRow(label: "WAVE TRACKER", detail: "The glowing sine wave shows your position within the set. The ball travels left to right across all reps, rising and falling with each eccentric and concentric phase. Red means eccentric, white means concentric.")
                        InfoRow(label: "SETS & REST", detail: "Configure multiple sets with automatic rest timers between them. The app counts down your rest and cues you when it's time to go again.")
                        InfoRow(label: "EXERCISE PRESETS", detail: "Select a common exercise to auto-fill recommended eccentric and concentric tempos, or set them manually for any movement.")
                        InfoRow(label: "LANDSCAPE MODE", detail: "Rotate your phone during a set for a wider view of the wave tracker — useful when your phone is propped up in a cage or on a bench.")
                    }

                    // Recommended tempos
                    InfoSection(title: "GETTING STARTED") {
                        InfoParagraph("A good starting tempo is 3 seconds eccentric, 1 second concentric. This is written as 3-1 in tempo notation and applies to almost any compound lift.")
                        InfoParagraph("As you build control, try 4-1 or 5-1 eccentrics. You'll likely need to reduce the weight — that's expected and correct.")
                        InfoParagraph("Rest 60–90 seconds between sets for hypertrophy work. Longer rest (2–3 min) is appropriate for heavier strength-focused sets.")
                    }

                    Spacer(minLength: 48)
                }
                .padding(.horizontal, 24)
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.fog)
                    .padding(10)
                    .background(AppTheme.panel)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.rim, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
    }
}

private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(AppTheme.blood)
                .padding(.top, 32)
            content()
        }
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.rim.opacity(0.5)).frame(height: 1)
        }
    }
}

private struct InfoParagraph: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .regular, design: .default))
            .foregroundStyle(AppTheme.fog)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct InfoRow: View {
    let label: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.parch)
            Text(detail)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AppTheme.fog)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
    }
}

private struct SetupScreen: View {
    @ObservedObject var viewModel: RepMetroViewModel
    @State private var showInfo = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 0) {
                            Text("REP ")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.parch)

                            Text("METRO")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.blood)
                        }

                        Text("TEMPO TRAINING · GUIDED REPS")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(4)
                            .foregroundStyle(AppTheme.fog)
                    }

                    Spacer()

                    Button { showInfo = true } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(AppTheme.fog)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 52)
                }
                .padding(.top, 48)
                .padding(.bottom, 32)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppTheme.rim)
                        .frame(height: 1)
                }
                .sheet(isPresented: $showInfo) {
                    InfoScreen()
                }

                VStack(alignment: .leading, spacing: 20) {
                    FieldGroup(label: "Configure Set") {
                        HStack(spacing: 8) {
                            NumberCell(title: "Sets", text: viewModel.binding(for: \.setsText), alignLeading: false)
                            NumberCell(title: "Reps", text: viewModel.binding(for: \.repsText), alignLeading: false)
                            NumberCell(title: "Rest (s)", text: viewModel.binding(for: \.restText), alignLeading: false)
                        }
                    }

                    Button {
                        viewModel.showExerciseModal = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(viewModel.selectedExercise?.name ?? "SELECT EXERCISE")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.parch)

                                Text(viewModel.selectedExercise?.detail ?? "Or set tempo manually")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.fog)
                            }

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.dust)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        PhaseChip(title: "ECCENTRIC", subtitle: "Lower · Lengthen")
                        PhaseChip(title: "CONCENTRIC", subtitle: "Lift · Contract")
                    }
                    .padding(.bottom, 8)

                    HStack(spacing: 8) {
                        NumberCell(title: "Seconds Down", text: viewModel.binding(for: \.eccentricText), alignLeading: false)
                        NumberCell(title: "Seconds Up", text: viewModel.binding(for: \.concentricText), alignLeading: false)
                    }

                    Button {
                        viewModel.beginWorkout()
                    } label: {
                        Text("BEGIN SET")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .tracking(8)
                            .foregroundStyle(AppTheme.parch)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(AppTheme.blood)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PressButtonStyle(pressedColor: AppTheme.rose))
                    .padding(.top, 8)
                }
                .padding(.top, 32)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(AppTheme.ink.ignoresSafeArea())
    }
}

private struct ActiveScreen: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: 0x3D0008)
                    .ignoresSafeArea()

                RadialGradient(
                    colors: viewModel.isEccentric
                        ? [AppTheme.blood.opacity(0.55), .clear]
                        : [AppTheme.parch.opacity(0.10), .clear],
                    center: viewModel.isEccentric ? .center : .top,
                    startRadius: 0,
                    endRadius: 360
                )
                .ignoresSafeArea()

                if geo.size.width > geo.size.height {
                    LandscapeActiveLayout(viewModel: viewModel)
                } else {
                    PortraitActiveLayout(viewModel: viewModel)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.duckBackgroundAudio()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            viewModel.unduckBackgroundAudio()
        }
    }
}

private struct PortraitActiveLayout: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SET \(viewModel.currentSet) · \(viewModel.totalSets)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(AppTheme.fog)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.rim, lineWidth: 1)
                    )

                Spacer()

                Button("STOP") {
                    viewModel.stopWorkout()
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.fog)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.rim, lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)

            Spacer()

            VStack(spacing: 0) {
                Text("\(viewModel.currentRep)")
                    .font(.system(size: 132, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.parch)
                    .shadow(color: AppTheme.parch.opacity(0.15), radius: 30)

                Text("OF \(viewModel.totalReps) REPS")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(5)
                    .foregroundStyle(AppTheme.fog)
                    .padding(.top, -4)
                    .padding(.bottom, 28)

                Text(viewModel.phaseTitle)
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                    .tracking(12)
                    .foregroundStyle(viewModel.isEccentric ? AppTheme.parch : AppTheme.rose)
                    .shadow(color: (viewModel.isEccentric ? AppTheme.parch : AppTheme.rose).opacity(0.25), radius: 24)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isEccentric)

                Text(viewModel.phaseSubtitle)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.fog)
                    .padding(.top, 10)
            }

            BallTracker(viewModel: viewModel)
                .frame(height: 160)
                .padding(.top, 24)
                .padding(.horizontal, 8)

            Spacer(minLength: 8)

            Button {
                viewModel.togglePause()
            } label: {
                Text(viewModel.isPaused ? "RESUME" : "PAUSE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(viewModel.isPaused ? AppTheme.parch : AppTheme.fog)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.isPaused ? AppTheme.blood : AppTheme.rim, lineWidth: 1)
                    )
                    .background(viewModel.isPaused ? AppTheme.panel.opacity(0.18) : .clear)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct LandscapeActiveLayout: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Left: stats + controls
            VStack(spacing: 0) {
                HStack {
                    Text("SET \(viewModel.currentSet) · \(viewModel.totalSets)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(AppTheme.fog)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))

                    Spacer()

                    Button("STOP") { viewModel.stopWorkout() }
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(AppTheme.fog)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
                }
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 4) {
                    Text("\(viewModel.currentRep)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.parch)

                    Text("OF \(viewModel.totalReps) REPS")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(AppTheme.fog)
                        .padding(.bottom, 10)

                    Text(viewModel.phaseTitle)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(viewModel.isEccentric ? AppTheme.parch : AppTheme.rose)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.isEccentric)

                    Text(viewModel.phaseSubtitle)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(AppTheme.fog)
                        .padding(.top, 4)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    viewModel.togglePause()
                } label: {
                    Text(viewModel.isPaused ? "RESUME" : "PAUSE")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(viewModel.isPaused ? AppTheme.parch : AppTheme.fog)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.isPaused ? AppTheme.blood : AppTheme.rim, lineWidth: 1)
                        )
                        .background(viewModel.isPaused ? AppTheme.panel.opacity(0.18) : .clear)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .frame(width: 240)

            Rectangle()
                .fill(AppTheme.rim)
                .frame(width: 1)
                .padding(.vertical, 20)

            // Right: ball tracker — takes remaining width
            BallTracker(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }
}

private struct BallTracker: View {
    @ObservedObject var viewModel: RepMetroViewModel
    private let ballSize: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let hPad: CGFloat = 20
            let labelH: CGFloat = 20
            let trackLeft = hPad
            let trackRight = geo.size.width - hPad
            let trackTop = labelH + 6
            let trackBottom = geo.size.height - labelH - 6
            let trackWidth = trackRight - trackLeft
            let centerY = (trackTop + trackBottom) / 2
            let amplitude = (trackBottom - trackTop) / 2
            let cx = geo.size.width / 2
            let n = max(viewModel.totalReps, 1)
            let steps = n * 50

            // Ball position along the sine wave
            let repPhase = viewModel.isEccentric
                ? viewModel.phaseProgress
                : 1 + viewModel.phaseProgress
            let tBall = (Double(viewModel.currentRep - 1) + repPhase / 2) / Double(n)
            let ballX = trackLeft + CGFloat(tBall) * trackWidth
            let ballY = centerY - amplitude * CGFloat(cos(tBall * Double(n) * 2 * .pi))
            let ballColor: Color = viewModel.isEccentric ? AppTheme.blood : AppTheme.parch
            let trailSteps = Int(tBall * Double(steps))

            ZStack {
                Text("UP")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.parch.opacity(0.5))
                    .position(x: cx, y: 10)

                Text("DOWN")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.parch.opacity(0.5))
                    .position(x: cx, y: geo.size.height - 10)

                // Dim base sine wave
                Path { path in
                    for i in 0...steps {
                        let t = Double(i) / Double(steps)
                        let x = trackLeft + CGFloat(t) * trackWidth
                        let y = centerY - amplitude * CGFloat(cos(t * Double(n) * 2 * .pi))
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else      { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(AppTheme.parch.opacity(0.18),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // Glowing completed trail
                if trailSteps > 0 {
                    Path { path in
                        for i in 0...trailSteps {
                            let t = Double(i) / Double(steps)
                            let x = trackLeft + CGFloat(t) * trackWidth
                            let y = centerY - amplitude * CGFloat(cos(t * Double(n) * 2 * .pi))
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else      { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(AppTheme.parch.opacity(0.6),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }

                // Ball with strong glow
                Circle()
                    .fill(ballColor)
                    .frame(width: ballSize, height: ballSize)
                    .shadow(color: ballColor, radius: 10)
                    .shadow(color: ballColor.opacity(0.6), radius: 24)
                    .position(x: ballX, y: ballY)
                    .animation(.linear(duration: 0.1), value: viewModel.phaseProgress)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isEccentric)
            }
        }
    }
}

private struct RestScreen: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("RECOVERY")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(6)
                .foregroundStyle(AppTheme.fog)
                .padding(.bottom, 8)

            Text("\(viewModel.restRemaining)")
                .font(.system(size: 142, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.restRemaining <= 10 ? AppTheme.rose : AppTheme.parch)

            Text("SECONDS REMAINING")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(5)
                .foregroundStyle(AppTheme.fog)
                .padding(.top, 4)
                .padding(.bottom, 40)

            Text("SET \(viewModel.currentSet) OF \(viewModel.totalSets) COMPLETE")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(4)
                .foregroundStyle(AppTheme.fog)
                .padding(.bottom, 40)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.rim)
                    Rectangle()
                        .fill(AppTheme.blood)
                        .frame(width: geometry.size.width * viewModel.restProgress)
                }
            }
            .frame(height: 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)

            VStack(spacing: 10) {
                Button {
                    viewModel.skipRest()
                } label: {
                    Text("START NEXT SET")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(AppTheme.parch)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(AppTheme.blood)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PressButtonStyle(pressedColor: AppTheme.rose))

                Button {
                    viewModel.stopWorkout()
                } label: {
                    Text("END WORKOUT")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(AppTheme.fog)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.rim, lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(AppTheme.deep.ignoresSafeArea())
    }
}

private struct LogScreen: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.isLastSet ? "WORKOUT COMPLETE" : "WELL DONE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(6)
                    .foregroundStyle(AppTheme.fog)
                    .padding(.bottom, 6)

                Text(viewModel.isLastSet ? "DONE" : "SET DONE")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(AppTheme.parch)
                    .padding(.bottom, 4)

                Text("SET \(viewModel.currentSet) OF \(viewModel.totalSets)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.fog)
                    .padding(.bottom, 28)

                HStack(spacing: 0) {
                    StatCell(value: "\(viewModel.totalReps)", label: "Reps")
                    StatCell(value: "\(viewModel.eccentricSeconds)s", label: "Ecc")
                    StatCell(value: "\(viewModel.concentricSeconds)s", label: "Con")
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.rim, lineWidth: 1)
                )
                .padding(.bottom, 24)

                Text("Rate of Perceived Exertion")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.fog)
                    .textCase(.uppercase)
                    .padding(.bottom, 8)

                HStack(spacing: 6) {
                    ForEach([6, 7, 8, 9, 10], id: \.self) { value in
                        Button {
                            viewModel.setRPE(value)
                        } label: {
                            Text("\(value)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.rpe == value ? AppTheme.parch : AppTheme.fog)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(viewModel.rpe == value ? AppTheme.blood : AppTheme.panel)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(viewModel.rpe == value ? AppTheme.blood : AppTheme.rim, lineWidth: 1))
                                .scaleEffect(viewModel.rpe == value ? 1.04 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: viewModel.rpe)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 6)

                Text(viewModel.rpeHint)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.fog)
                    .frame(minHeight: 14, alignment: .leading)
                    .padding(.bottom, 20)

                // Primary action — filled
                Button {
                    viewModel.logAndContinue()
                } label: {
                    Text(viewModel.isLastSet ? "DONE" : "REST")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(AppTheme.parch)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.blood)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PressButtonStyle(pressedColor: AppTheme.rose))
                .padding(.bottom, 8)

                HStack(spacing: 8) {
                    // Secondary action
                    Button {
                        viewModel.logAndFinish()
                    } label: {
                        Text("FINISH")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(AppTheme.fog)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    // Tertiary action
                    Button {
                        viewModel.skipLog()
                    } label: {
                        Text(viewModel.isLastSet ? "SKIP" : "SKIP → REST")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .tracking(3)
                            .foregroundStyle(AppTheme.fog)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 32)
        }
        .background(AppTheme.ink.ignoresSafeArea())
    }
}

private struct ExerciseModal: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("EXERCISES")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(AppTheme.parch)

                Spacer()

                Button("CLOSE ✕") {
                    viewModel.showExerciseModal = false
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.fog)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.rim, lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 20)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.rim)
                    .frame(height: 1)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.exerciseSections) { section in
                        Text(section.title)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .tracking(5)
                            .foregroundStyle(AppTheme.rose)
                            .padding(.top, 14)
                            .padding(.bottom, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(AppTheme.rim)
                                    .frame(height: 1)
                            }

                        ForEach(section.exercises) { exercise in
                            Button {
                                viewModel.pickExercise(exercise)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.name)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .tracking(2)
                                            .foregroundStyle(AppTheme.parch)

                                        Text(exercise.detail)
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .tracking(2)
                                            .foregroundStyle(AppTheme.fog)
                                    }

                                    Spacer()

                                    Text("\(exercise.eccentric)s / \(exercise.concentric)s")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .tracking(2)
                                        .foregroundStyle(AppTheme.fog)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppTheme.rim, lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(AppTheme.panel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.ink.opacity(0.96).ignoresSafeArea())
    }
}

private struct FieldGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(AppTheme.fog)
                .textCase(.uppercase)

            content
        }
    }
}

private struct NumberCell: View {
    let title: String
    @Binding var text: String
    let alignLeading: Bool

    var body: some View {
        VStack(alignment: alignLeading ? .leading : .center, spacing: 4) {
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(alignLeading ? .leading : .center)
                .font(.system(size: title.isEmpty ? 30 : 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.parch)

            if !title.isEmpty {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.fog)
            }
        }
        .padding(.horizontal, alignLeading ? 14 : 8)
        .padding(.vertical, title.isEmpty ? 10 : 14)
        .frame(maxWidth: .infinity, alignment: alignLeading ? .leading : .center)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
    }
}

private struct PhaseChip: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(AppTheme.parch)

            Text(subtitle.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.fog)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
    }
}

private struct TickRow: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...max(total, 1), id: \.self) { index in
                Circle()
                    .fill(color(for: index))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == current ? 1.3 : 1.0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func color(for index: Int) -> Color {
        if index < current { return AppTheme.blood }
        if index == current { return AppTheme.parch }
        return AppTheme.dust
    }
}

private struct ArcTimerView: View {
    let progress: Double
    let remainingText: String
    let strokeColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.dust.opacity(0.4), lineWidth: 2)
                .frame(width: 130, height: 130)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 130, height: 130)

            VStack(spacing: 0) {
                Text(remainingText)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.parch)

                Text("SEC")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.fog)
                    .padding(.top, -2)
            }
        }
    }
}

private struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.parch)

            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(AppTheme.fog)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppTheme.rim)
                .frame(width: 1)
        }
    }
}

private struct BarbellGlyph: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let barHeight = height * 0.14

            ZStack {
                Rectangle()
                    .fill(AppTheme.blood)
                    .frame(width: width * 0.4, height: barHeight)

                HStack(spacing: width * 0.42) {
                    Rectangle().fill(AppTheme.blood).frame(width: width * 0.11, height: height * 0.24)
                    Rectangle().fill(AppTheme.blood).frame(width: width * 0.11, height: height * 0.24)
                }

                HStack(spacing: width * 0.63) {
                    Rectangle().fill(AppTheme.blood).frame(width: width * 0.15, height: height * 0.42)
                    Rectangle().fill(AppTheme.blood).frame(width: width * 0.15, height: height * 0.42)
                }

                HStack(spacing: width * 0.8) {
                    Rectangle().fill(AppTheme.blood).frame(width: width * 0.18, height: height * 0.22)
                    Rectangle().fill(AppTheme.blood).frame(width: width * 0.18, height: height * 0.22)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                stride(from: 0.0, through: geometry.size.height, by: 4.0).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.black.opacity(0.04), lineWidth: 1)
        }
    }
}

private struct PressButtonStyle: ButtonStyle {
    let pressedColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? pressedColor : nil)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}


private final class RepMetroViewModel: NSObject, ObservableObject {
    @Published var currentScreen: Screen = .setup
    @Published var showSplash = true
    @Published var showExerciseModal = false

    @Published var setsText = "3"
    @Published var repsText = "8"
    @Published var restText = "90"
    @Published var eccentricText = "3"
    @Published var concentricText = "1"

    @Published var selectedExercise: ExercisePreset?

    @Published var currentSet = 1
    @Published var currentRep = 1
    @Published var isEccentric = true
    @Published var isPaused = false
    @Published var phaseElapsed: Double = 0
    @Published var phaseDuration: Double = 1
    @Published var restRemaining = 90
    @Published var restTotal = 90

    @Published var rpe: Int?

    let exerciseSections = ExerciseSection.library

    private let speech = AVSpeechSynthesizer()
    private lazy var bestVoice: AVSpeechSynthesisVoice = {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return voices.first(where: { $0.language.hasPrefix("en-US") && $0.quality == .premium })
            ?? voices.first(where: { $0.language.hasPrefix("en-US") && $0.quality == .enhanced })
            ?? AVSpeechSynthesisVoice(language: "en-US")
            ?? voices[0]
    }()
    private var audioPlayers: [AVAudioPlayer] = []
    private var phaseTimer: Timer?
    private var restTimer: Timer?
    private var splashTask: Task<Void, Never>?
    private var hasStartedSplash = false

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func duckBackgroundAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func unduckBackgroundAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func startSplashSequence() {
        guard !hasStartedSplash else { return }
        hasStartedSplash = true

        splashTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            showSplash = false
        }
    }

    func binding(for keyPath: ReferenceWritableKeyPath<RepMetroViewModel, String>) -> Binding<String> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { self[keyPath: keyPath] = $0.filteredDigits }
        )
    }

    var totalSets: Int { max(Int(setsText) ?? 3, 1) }
    var totalReps: Int { max(Int(repsText) ?? 8, 1) }
    var restSeconds: Int { max(Int(restText) ?? 90, 0) }
    var eccentricSeconds: Int { max(Int(eccentricText) ?? 3, 1) }
    var concentricSeconds: Int { max(Int(concentricText) ?? 1, 1) }

    var phaseTitle: String { isEccentric ? "DOWN" : "UP" }
    var phaseSubtitle: String { isEccentric ? "ECCENTRIC · LOWER THE WEIGHT" : "CONCENTRIC · DRIVE THE WEIGHT" }
    var phaseProgress: Double { min(max(phaseElapsed / max(phaseDuration, 0.1), 0), 1) }
    var phaseRemainingText: String {
        let remaining = max(phaseDuration - phaseElapsed, 0)
        return remaining < 1 ? String(format: "%.1f", remaining) : "\(Int(ceil(remaining)))"
    }

    var isLastSet: Bool { currentSet >= totalSets }
    var rpeHint: String {
        guard let rpe else { return "" }
        return Self.rpeDescriptions[rpe] ?? ""
    }

    var restProgress: Double {
        guard restTotal > 0 else { return 0 }
        return Double(restRemaining) / Double(restTotal)
    }

    func pickExercise(_ exercise: ExercisePreset) {
        selectedExercise = exercise
        eccentricText = "\(exercise.eccentric)"
        concentricText = "\(exercise.concentric)"
        showExerciseModal = false
    }

    func beginWorkout() {
        sanitizeInputs()
        currentSet = 1
        currentRep = 1
        isEccentric = true
        isPaused = false
        rpe = nil
        move(to: .active)
        let goRate: Float = 0.85
        let goUrl = Bundle.main.url(forResource: "set_go_1", withExtension: "mp3")
            ?? Bundle.main.url(forResource: "set_go_1", withExtension: "mp3", subdirectory: "AudioCues")
        let goDuration = (goUrl.flatMap { try? AVAudioPlayer(contentsOf: $0) }?.duration ?? 2.0) / Double(goRate)
        speak("Set 1. Let's go.", delay: 1.0, rate: goRate)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + goDuration + 1.0) {
            self.speakRepComplete()
            self.startPhase(speechDelay: 0.65)
        }
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopAudio()
        }
    }

    func stopWorkout() {
        invalidateTimers()
        stopAudio()
        move(to: .setup)
    }

    func skipRest() {
        restTimer?.invalidate()
        stopAudio()
        currentSet += 1
        impact(style: .heavy)
        speak("Set \(currentSet). Let's go.", delay: 0.2)
        startCurrentSet()
    }

    func setRPE(_ value: Int) {
        rpe = value
        impact(style: .light)
    }

    func logAndContinue() {
        if isLastSet {
            move(to: .setup)
        } else {
            startRest()
        }
    }

    func logAndFinish() {
        move(to: .setup)
    }

    func skipLog() {
        if isLastSet {
            move(to: .setup)
        } else {
            startRest()
        }
    }

    private func startCurrentSet() {
        currentRep = 1
        isEccentric = true
        isPaused = false
        move(to: .active)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            self.speakRepComplete()
            self.startPhase(speechDelay: 0.65)
        }
    }

    private func startPhase(speechDelay: Double = 0) {
        phaseTimer?.invalidate()
        phaseDuration = Double(isEccentric ? eccentricSeconds : concentricSeconds)
        phaseElapsed = 0
        speakPhase(delay: speechDelay)
        impact(style: isEccentric ? .medium : .light)

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard !self.isPaused else { return }

            self.phaseElapsed += 0.1
            if self.phaseElapsed >= self.phaseDuration {
                self.phaseTimer?.invalidate()
                self.nextPhase()
            }
        }
    }

    private func nextPhase() {
        if isEccentric {
            isEccentric = false
            startPhase()
        } else if currentRep >= totalReps {
            finishSet()
        } else {
            currentRep += 1
            speakRepComplete()
            isEccentric = true
            startPhase(speechDelay: 0.65)
        }
    }

    private func finishSet() {
        phaseTimer?.invalidate()
        notification(type: .success)
        stopAudio()

        let message = isLastSet
            ? "That's a wrap. \(totalSets) sets done. Great work today."
            : "Set \(currentSet) done. Take your rest."
        speak(message)

        rpe = nil
        move(to: .log)
    }

    private func startRest() {
        move(to: .rest)
        restTotal = restSeconds
        restRemaining = restSeconds

        if restSeconds == 0 {
            skipRest()
            return
        }

        speak("Good work. Rest for \(restSeconds) seconds.")
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.restRemaining -= 1

            if self.restRemaining == 10 {
                self.impact(style: .medium)
                self.stopAudio()
                self.speak("Ten seconds remaining.")
            } else if self.restRemaining == 3 {
                self.impact(style: .medium)
                self.stopAudio()
                self.speak("Three. Two. One.")
            } else if self.restRemaining <= 0 {
                self.restTimer?.invalidate()
                self.skipRest()
            }
        }
    }

    private func move(to screen: Screen) {
        currentScreen = screen
        if screen == .setup {
            invalidateTimers()
            stopAudio()
        }
    }

    private func sanitizeInputs() {
        setsText = "\(min(max(totalSets, 1), 20))"
        repsText = "\(min(max(totalReps, 1), 50))"
        restText = "\(min(max(restSeconds, 0), 600))"
        eccentricText = "\(min(max(eccentricSeconds, 1), 30))"
        concentricText = "\(min(max(concentricSeconds, 1), 30))"
    }

    private func invalidateTimers() {
        phaseTimer?.invalidate()
        restTimer?.invalidate()
        phaseTimer = nil
        restTimer = nil
        isPaused = false
    }

    private func speakPhase(delay: Double = 0) {
        if isEccentric {
            speak("Down.", delay: delay)
        } else {
            speak("Up.")
        }
    }

    private func speakRepComplete() {
        speak("\(currentRep).")
    }

    private func speak(_ text: String, delay: Double = 0, rate: Float = 1.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Try pre-generated bundle audio first (root or AudioCues subfolder)
            if let key = Self.bundleKey(for: text) {
                let url = Bundle.main.url(forResource: key, withExtension: "mp3")
                    ?? Bundle.main.url(forResource: key, withExtension: "mp3", subdirectory: "AudioCues")
                if let url, let player = try? AVAudioPlayer(contentsOf: url) {
                    self.audioPlayers.removeAll { !$0.isPlaying }
                    self.audioPlayers.append(player)
                    if rate != 1.0 {
                        player.enableRate = true
                        player.rate = rate
                    }
                    player.play()
                    return
                }
            }
            // Fallback: system voice
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = self.bestVoice
            utterance.rate = 0.50
            utterance.volume = 0.9
            utterance.preUtteranceDelay = 0.05
            utterance.postUtteranceDelay = 0.08
            self.speech.speak(utterance)
        }
    }

    private static func bundleKey(for text: String) -> String? {
        switch text {
        case "Down.":                  return "down"
        case "Up.":                    return "up"
        case "Ten seconds remaining.": return "ten_seconds"
        case "Three. Two. One.":       return "countdown"
        default: break
        }
        // Rep complete number cue e.g. "1." "2."
        if text.hasSuffix("."), let n = Int(text.dropLast(1)) {
            return "rep_\(n)"
        }
        if text.hasPrefix("Set ") && text.hasSuffix(". Let's go.") {
            let mid = text.dropFirst(4).dropLast(11)
            if let n = Int(mid) { return "set_go_\(n)" }
        }
        if text.hasPrefix("Set ") && text.hasSuffix(" done. Take your rest.") {
            let mid = text.dropFirst(4).dropLast(22)
            if let n = Int(mid) { return "set_done_\(n)" }
        }
        if text.hasPrefix("That's a wrap. ") {
            let parts = text.dropFirst(15).components(separatedBy: " ")
            if let n = Int(parts[0]) { return "complete_\(n)" }
        }
        if text.hasPrefix("Good work. Rest for ") && text.hasSuffix(" seconds.") {
            let mid = text.dropFirst(20).dropLast(9)
            if let n = Int(mid) { return "rest_\(n)" }
        }
        return nil
    }

    private func stopAudio() {
        audioPlayers.forEach { $0.stop() }
        audioPlayers.removeAll()
        speech.stopSpeaking(at: .immediate)
    }

    private func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    private static let rpeDescriptions: [Int: String] = [
        6: "Easy — many reps left",
        7: "Moderate — 3+ in reserve",
        8: "Hard — 2 reps left",
        9: "Very hard — 1 rep left",
        10: "Max — nothing left"
    ]
}

private extension RepMetroViewModel {
    enum Screen {
        case setup
        case active
        case rest
        case log
    }
}

private struct ExerciseSection: Identifiable {
    let id = UUID()
    let title: String
    let exercises: [ExercisePreset]

    static let library: [ExerciseSection] = [
        ExerciseSection(title: "CHEST", exercises: [
            ExercisePreset(name: "BENCH PRESS", eccentric: 3, concentric: 1, detail: "3s lower · 1s press"),
            ExercisePreset(name: "INCLINE PRESS", eccentric: 3, concentric: 1, detail: "3s lower · 1s press"),
            ExercisePreset(name: "DUMBBELL FLYE", eccentric: 4, concentric: 1, detail: "4s stretch · 1s squeeze"),
            ExercisePreset(name: "PUSH UP", eccentric: 3, concentric: 1, detail: "3s lower · 1s push"),
            ExercisePreset(name: "CABLE CROSSOVER", eccentric: 3, concentric: 2, detail: "3s open · 2s close")
        ]),
        ExerciseSection(title: "BACK", exercises: [
            ExercisePreset(name: "PULL UP", eccentric: 3, concentric: 1, detail: "3s lower · 1s pull"),
            ExercisePreset(name: "BARBELL ROW", eccentric: 3, concentric: 1, detail: "3s lower · 1s row"),
            ExercisePreset(name: "LAT PULLDOWN", eccentric: 3, concentric: 1, detail: "3s up · 1s pull"),
            ExercisePreset(name: "SEATED ROW", eccentric: 3, concentric: 1, detail: "3s extend · 1s pull"),
            ExercisePreset(name: "DEADLIFT", eccentric: 3, concentric: 1, detail: "3s lower · 1s lift")
        ]),
        ExerciseSection(title: "LEGS", exercises: [
            ExercisePreset(name: "SQUAT", eccentric: 3, concentric: 1, detail: "3s down · 1s drive"),
            ExercisePreset(name: "LEG PRESS", eccentric: 3, concentric: 1, detail: "3s lower · 1s press"),
            ExercisePreset(name: "ROMANIAN DEADLIFT", eccentric: 3, concentric: 1, detail: "3s hinge · 1s return"),
            ExercisePreset(name: "LEG CURL", eccentric: 3, concentric: 2, detail: "3s extend · 2s curl"),
            ExercisePreset(name: "LEG EXTENSION", eccentric: 3, concentric: 2, detail: "3s lower · 2s extend"),
            ExercisePreset(name: "LUNGE", eccentric: 3, concentric: 1, detail: "3s down · 1s drive"),
            ExercisePreset(name: "CALF RAISE", eccentric: 4, concentric: 1, detail: "4s lower · 1s raise")
        ]),
        ExerciseSection(title: "SHOULDERS", exercises: [
            ExercisePreset(name: "OVERHEAD PRESS", eccentric: 3, concentric: 1, detail: "3s lower · 1s press"),
            ExercisePreset(name: "LATERAL RAISE", eccentric: 3, concentric: 2, detail: "3s lower · 2s raise"),
            ExercisePreset(name: "FRONT RAISE", eccentric: 3, concentric: 2, detail: "3s lower · 2s raise"),
            ExercisePreset(name: "FACE PULL", eccentric: 3, concentric: 2, detail: "3s extend · 2s pull")
        ]),
        ExerciseSection(title: "ARMS", exercises: [
            ExercisePreset(name: "BICEP CURL", eccentric: 3, concentric: 2, detail: "3s lower · 2s curl"),
            ExercisePreset(name: "TRICEP PUSHDOWN", eccentric: 3, concentric: 2, detail: "3s up · 2s push"),
            ExercisePreset(name: "SKULL CRUSHER", eccentric: 3, concentric: 1, detail: "3s lower · 1s press"),
            ExercisePreset(name: "HAMMER CURL", eccentric: 3, concentric: 2, detail: "3s lower · 2s curl")
        ])
    ]
}

private struct ExercisePreset: Identifiable {
    let id = UUID()
    let name: String
    let eccentric: Int
    let concentric: Int
    let detail: String
}

private extension String {
    var filteredDigits: String {
        filter { $0.isNumber }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex & 0xFF0000) >> 16) / 255,
            green: Double((hex & 0x00FF00) >> 8) / 255,
            blue: Double(hex & 0x0000FF) / 255
        )
    }
}

#Preview {
    ContentView()
}
