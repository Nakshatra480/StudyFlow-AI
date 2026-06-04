import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let timeString: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 16)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
            
            Text(timeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(width: 220, height: 220)
    }
}
