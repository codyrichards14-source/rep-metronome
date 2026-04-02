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
                case .active:
                    ActiveScreen(viewModel: viewModel)
                case .rest:
                    RestScreen(viewModel: viewModel)
                case .log:
                    LogScreen(viewModel: viewModel)
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
    static let ink = Color(hex: 0x0E0608)
    static let deep = Color(hex: 0x180C0E)
    static let panel = Color(hex: 0x1F1012)
    static let card = Color(hex: 0x261416)
    static let rim = Color(hex: 0x3D1C20)
    static let dust = Color(hex: 0x7A4A50)
    static let fog = Color(hex: 0xB08A8E)
    static let parch = Color(hex: 0xF2E8DF)
    static let blood = Color(hex: 0x8B0021)
    static let rose = Color(hex: 0xC41840)
}

private struct SplashScreen: View {
    @State private var animateLine = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .stroke(AppTheme.blood, lineWidth: 1)
                    .frame(width: 88, height: 88)

                Rectangle()
                    .stroke(AppTheme.blood.opacity(0.3), lineWidth: 1)
                    .frame(width: 78, height: 78)

                BarbellGlyph()
                    .frame(width: 44, height: 44)
            }
            .padding(.bottom, 28)

            Text("REP METRO")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .tracking(10)
                .foregroundStyle(AppTheme.parch)

            Text("TEMPO TRAINING · GUIDED REPS")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(5)
                .foregroundStyle(AppTheme.dust)
                .padding(.top, 8)

            Rectangle()
                .fill(AppTheme.blood)
                .frame(width: 1, height: animateLine ? 48 : 0)
                .padding(.top, 36)
                .animation(.easeOut(duration: 1.8).delay(0.3), value: animateLine)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.ink.ignoresSafeArea())
        .onAppear {
            animateLine = true
        }
    }
}

private struct SetupScreen: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
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
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(AppTheme.dust)
                }
                .padding(.top, 48)
                .padding(.bottom, 32)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppTheme.rim)
                        .frame(height: 1)
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
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.dust)
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
        ZStack {
            AppTheme.deep
                .ignoresSafeArea()

            RadialGradient(
                colors: viewModel.isEccentric
                    ? [AppTheme.blood.opacity(0.22), .clear]
                    : [AppTheme.parch.opacity(0.08), .clear],
                center: viewModel.isEccentric ? .center : .top,
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("SET \(viewModel.currentSet) · \(viewModel.totalSets)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(AppTheme.dust)
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
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.dust)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.rim, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)

                TickRow(total: viewModel.totalReps, current: viewModel.currentRep)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 0) {
                    Text("\(viewModel.currentRep)")
                        .font(.system(size: 132, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.parch)
                        .shadow(color: AppTheme.parch.opacity(0.15), radius: 30)

                    Text("OF \(viewModel.totalReps) REPS")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(6)
                        .foregroundStyle(AppTheme.dust)
                        .padding(.top, -4)
                        .padding(.bottom, 28)

                    Text(viewModel.phaseTitle)
                        .font(.system(size: 84, weight: .bold, design: .rounded))
                        .tracking(12)
                        .foregroundStyle(viewModel.isEccentric ? AppTheme.parch : AppTheme.rose)
                        .shadow(color: (viewModel.isEccentric ? AppTheme.parch : AppTheme.rose).opacity(0.25), radius: 24)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.isEccentric)

                    Text(viewModel.phaseSubtitle)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(5)
                        .foregroundStyle(AppTheme.dust)
                        .padding(.top, 10)

                    ArcTimerView(progress: viewModel.phaseProgress,
                                 remainingText: viewModel.phaseRemainingText,
                                 strokeColor: viewModel.isEccentric ? AppTheme.blood : AppTheme.parch)
                        .padding(.top, 28)
                }

                Spacer()

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
}

private struct RestScreen: View {
    @ObservedObject var viewModel: RepMetroViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("RECOVERY")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(6)
                .foregroundStyle(AppTheme.dust)
                .padding(.bottom, 8)

            Text("\(viewModel.restRemaining)")
                .font(.system(size: 142, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.restRemaining <= 10 ? AppTheme.rose : AppTheme.parch)

            Text("SECONDS REMAINING")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(6)
                .foregroundStyle(AppTheme.dust)
                .padding(.top, 4)
                .padding(.bottom, 40)

            Text("SET \(viewModel.currentSet) OF \(viewModel.totalSets) COMPLETE")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(4)
                .foregroundStyle(AppTheme.dust)
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
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(6)
                    .foregroundStyle(AppTheme.dust)
                    .padding(.bottom, 6)

                Text(viewModel.isLastSet ? "DONE" : "SET DONE")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(AppTheme.parch)
                    .padding(.bottom, 4)

                Text("SET \(viewModel.currentSet) OF \(viewModel.totalSets)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.dust)
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
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.dust)
                    .textCase(.uppercase)
                    .padding(.bottom, 8)

                HStack(spacing: 6) {
                    ForEach([6, 7, 8, 9, 10], id: \.self) { value in
                        Button {
                            viewModel.setRPE(value)
                        } label: {
                            Text("\(value)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.rpe == value ? AppTheme.parch : AppTheme.dust)
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
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.dust)
                    .frame(minHeight: 14, alignment: .leading)
                    .padding(.bottom, 20)

                LogField(label: "Exercise") {
                    TextField("", text: $viewModel.logExercise)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .keyboardType(.alphabet)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(AppTheme.parch)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(AppTheme.dust)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        NumberCell(title: "", text: $viewModel.logWeightText, alignLeading: true)

                        Picker("Unit", selection: $viewModel.logUnit) {
                            Text("KG").tag("kg")
                            Text("LBS").tag("lbs")
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.parch)
                        .frame(minWidth: 72)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
                    }

                    Text(viewModel.weightHint)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(AppTheme.blood)
                        .frame(minHeight: 14, alignment: .leading)
                }
                .padding(.bottom, 24)

                Text(viewModel.tutText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(AppTheme.fog)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
                    .padding(.bottom, 24)

                // Primary action — filled
                Button {
                    viewModel.logAndContinue()
                } label: {
                    Text(viewModel.isLastSet ? "LOG SET" : "LOG + REST")
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
                        Text("LOG + DONE")
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
                            .foregroundStyle(AppTheme.dust)
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
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.dust)
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
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .tracking(5)
                            .foregroundStyle(AppTheme.blood)
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
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .tracking(2)
                                            .foregroundStyle(AppTheme.dust)
                                    }

                                    Spacer()

                                    Text("\(exercise.eccentric)s / \(exercise.concentric)s")
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .tracking(2)
                                        .foregroundStyle(AppTheme.dust)
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
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(4)
                .foregroundStyle(AppTheme.dust)
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
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(AppTheme.dust)
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
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.dust)
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
        return AppTheme.rim
    }
}

private struct ArcTimerView: View {
    let progress: Double
    let remainingText: String
    let strokeColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.rim, lineWidth: 2)
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
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(AppTheme.dust)
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
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .tracking(3)
                .foregroundStyle(AppTheme.dust)
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

private struct LogField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(4)
                .foregroundStyle(AppTheme.dust)
                .textCase(.uppercase)

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rim, lineWidth: 1))
        }
        .padding(.bottom, 16)
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
    @Published var logExercise = ""
    @Published var logWeightText = ""
    @Published var logUnit = "kg"

    let exerciseSections = ExerciseSection.library

    private let speech = AVSpeechSynthesizer()
    private lazy var bestVoice: AVSpeechSynthesisVoice = {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return voices.first(where: { $0.language.hasPrefix("en-US") && $0.quality == .premium })
            ?? voices.first(where: { $0.language.hasPrefix("en-US") && $0.quality == .enhanced })
            ?? AVSpeechSynthesisVoice(language: "en-US")
            ?? voices[0]
    }()
    private var phaseTimer: Timer?
    private var restTimer: Timer?
    private var splashTask: Task<Void, Never>?
    private let storage = WorkoutLogStore()
    private var hasStartedSplash = false

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

    var weightHint: String {
        let name = normalizedExerciseName
        guard !name.isEmpty,
              let last = storage.logs.first(where: { $0.exercise == name && $0.weight > 0 })
        else { return "" }

        let weightText = last.weight.cleanNumber
        return "LAST SESSION: \(weightText)\(last.unit.uppercased()) × \(last.reps) REPS"
    }

    var tutText: String {
        let tut = totalReps * (eccentricSeconds + concentricSeconds)
        let weight = Double(logWeightText) ?? 0
        if weight > 0 {
            let score = (weight * Double(tut) / 60.0 * 10).rounded() / 10
            return "\(tut)S TIME UNDER TENSION · \(score.cleanNumber) \(logUnit.uppercased())·MIN"
        }
        return "\(tut)S TIME UNDER TENSION"
    }

    var restProgress: Double {
        guard restTotal > 0 else { return 0 }
        return Double(restRemaining) / Double(restTotal)
    }

    func pickExercise(_ exercise: ExercisePreset) {
        selectedExercise = exercise
        eccentricText = "\(exercise.eccentric)"
        concentricText = "\(exercise.concentric)"
        logExercise = exercise.name
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
        speak("Set 1. Let's go.", delay: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.startPhase()
        }
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            speech.stopSpeaking(at: .immediate)
        }
    }

    func stopWorkout() {
        invalidateTimers()
        speech.stopSpeaking(at: .immediate)
        move(to: .setup)
    }

    func skipRest() {
        restTimer?.invalidate()
        speech.stopSpeaking(at: .immediate)
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
        saveLog()
        if isLastSet {
            move(to: .setup)
        } else {
            startRest()
        }
    }

    func logAndFinish() {
        saveLog()
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
        startPhase()
    }

    private func startPhase() {
        phaseTimer?.invalidate()
        phaseDuration = Double(isEccentric ? eccentricSeconds : concentricSeconds)
        phaseElapsed = 0
        speakPhase()
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
            isEccentric = true
            startPhase()
        }
    }

    private func finishSet() {
        phaseTimer?.invalidate()
        notification(type: .success)
        speech.stopSpeaking(at: .immediate)

        let message = isLastSet
            ? "That's a wrap. \(totalSets) sets done. Great work today."
            : "Set \(currentSet) done. Take your rest."
        speak(message)

        rpe = nil
        logWeightText = ""
        if let selectedExercise {
            logExercise = selectedExercise.name
        }
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
                self.speech.stopSpeaking(at: .immediate)
                self.speak("Ten seconds remaining.")
            } else if self.restRemaining == 3 {
                self.impact(style: .medium)
                self.speech.stopSpeaking(at: .immediate)
                self.speak("Three. Two. One.")
            } else if self.restRemaining <= 0 {
                self.restTimer?.invalidate()
                self.skipRest()
            }
        }
    }

    private func saveLog() {
        let entry = WorkoutLogEntry(
            date: Date(),
            exercise: normalizedExerciseName.isEmpty ? "SET" : normalizedExerciseName,
            reps: totalReps,
            eccentric: eccentricSeconds,
            concentric: concentricSeconds,
            weight: Double(logWeightText) ?? 0,
            unit: logUnit,
            tut: totalReps * (eccentricSeconds + concentricSeconds),
            rpe: rpe
        )
        storage.save(entry)
    }

    private var normalizedExerciseName: String {
        logExercise.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func move(to screen: Screen) {
        currentScreen = screen
        if screen == .setup {
            invalidateTimers()
            speech.stopSpeaking(at: .immediate)
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

    private func speakPhase() {
        if isEccentric {
            speak("Rep \(currentRep). Down.")
        } else {
            speak("Up.")
        }
    }

    private func speak(_ text: String, delay: Double = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = self.bestVoice
            utterance.rate = 0.50
            utterance.volume = 0.9
            utterance.preUtteranceDelay = 0.05
            utterance.postUtteranceDelay = 0.08
            self.speech.speak(utterance)
        }
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

private struct WorkoutLogEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let exercise: String
    let reps: Int
    let eccentric: Int
    let concentric: Int
    let weight: Double
    let unit: String
    let tut: Int
    let rpe: Int?

    init(date: Date, exercise: String, reps: Int, eccentric: Int, concentric: Int, weight: Double, unit: String, tut: Int, rpe: Int?) {
        id = UUID()
        self.date = date
        self.exercise = exercise
        self.reps = reps
        self.eccentric = eccentric
        self.concentric = concentric
        self.weight = weight
        self.unit = unit
        self.tut = tut
        self.rpe = rpe
    }
}

private struct WorkoutLogStore {
    private let key = "rm3_logs"

    var logs: [WorkoutLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let logs = try? JSONDecoder().decode([WorkoutLogEntry].self, from: data)
        else {
            return []
        }
        return logs.sorted { $0.date > $1.date }
    }

    func save(_ entry: WorkoutLogEntry) {
        var updated = logs
        updated.insert(entry, at: 0)
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private extension String {
    var filteredDigits: String {
        filter { $0.isNumber }
    }
}

private extension Double {
    var cleanNumber: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
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
