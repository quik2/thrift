import SwiftUI
import Charts

struct PriceHistoryChart: View {
    let dataPoints: [PriceDataPoint]
    @State private var selectedPoint: PriceDataPoint?
    @State private var tooltipOpacity: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    private var minValue: Double {
        (dataPoints.map(\.value).min() ?? 0) * 0.85
    }

    private var maxValue: Double {
        (dataPoints.map(\.value).max() ?? 100) * 1.1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TFSpacing.md) {
            // Time range chips
            HStack(spacing: TFSpacing.sm) {
                ForEach(["1W", "1M", "3M", "ALL"], id: \.self) { range in
                    Text(range)
                        .font(.system(size: 12, weight: range == "ALL" ? .semibold : .regular))
                        .foregroundStyle(range == "ALL" ? (colorScheme == .dark ? Color.white : Color.white) : Color.tfTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(range == "ALL" ? TFColor.gainGreen.opacity(colorScheme == .dark ? 0.3 : 0.85) : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            // Chart
            Chart {
                ForEach(dataPoints) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Min", minValue),
                        yEnd: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                TFColor.gainGreen.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                TFColor.gainGreen.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TFColor.gainGreen, TFColor.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Scrub indicator
                if let selected = selectedPoint {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(Color.tfTextTertiary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    PointMark(
                        x: .value("Date", selected.date),
                        y: .value("Value", selected.value)
                    )
                    .symbol {
                        ZStack {
                            Circle()
                                .fill(TFColor.gainGreen)
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(Color.tfBackground)
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }
            .chartYScale(domain: minValue...maxValue)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(dataPoints.count / 4, 1))) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(TFFont.micro)
                        .foregroundStyle(Color.tfTextTertiary)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                    if let date: Date = proxy.value(atX: x) {
                                        if let closest = dataPoints.min(by: {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        }) {
                                            if selectedPoint?.id != closest.id {
                                                selectedPoint = closest
                                                tooltipOpacity = 1
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3).delay(1.5)) {
                                        tooltipOpacity = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        selectedPoint = nil
                                    }
                                }
                        )
                }
            }
            .frame(height: 170)

            // Tooltip
            if let selected = selectedPoint {
                HStack(spacing: TFSpacing.sm) {
                    Text(formatPrice(selected.value))
                        .font(TFFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(Color.tfTextPrimary)

                    Text(selected.date, format: .dateTime.month(.abbreviated).day())
                        .font(TFFont.micro)
                        .foregroundStyle(Color.tfTextSecondary)
                }
                .padding(.horizontal, TFSpacing.sm)
                .padding(.vertical, TFSpacing.xs)
                .background(Color.tfCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: TFRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: TFRadius.small)
                        .stroke(TFColor.borderSubtle, lineWidth: 1)
                )
                .opacity(tooltipOpacity)
                .transition(.opacity)
            }
        }
        .padding(TFSpacing.md)
        .tfGlassCard()
        .accessibilityLabel("Price history chart, \(dataPoints.count) data points")
    }

    private func formatPrice(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "$\(Int(value))"
        }
        return String(format: "$%.0f", value)
    }
}
