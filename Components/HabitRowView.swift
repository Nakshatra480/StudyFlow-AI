import SwiftUI

struct HabitRowView: View {
    let habit: HabitItem
    let isCompletedToday: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(habit.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(habit.streak) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: isCompletedToday ? "checkmark.square.fill" : "square")
                    .font(.title)
                    .foregroundColor(isCompletedToday ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
