import Foundation

class AXSharedTimer {
    static let shared = AXSharedTimer()
    
    // The timer value in seconds
    private(set) var timerValue: Int = 0 {
        didSet {
            // Notify observers when timer value changes
            NotificationCenter.default.post(name: .AXSharedTimerValueDidChange, object: self)
            
            // If timer reaches zero, notify completion and stop
            if timerValue == 0 && oldValue > 0 {
                NotificationCenter.default.post(name: .AXSharedTimerDidComplete, object: self)
                print("TIMER ENDEDDDDDD")
                stopTimer()
            }
        }
    }
    
    // Timer state
    private(set) var isRunning: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .AXSharedTimerValueDidChange, object: self)
        }
    }
    
    private var timer: Timer?
    
    private init() {}
    
    // Set timer value (in minutes) and automatically start
    func setTimerValue(_ minutes: Int, autoStart: Bool = true) {
        stopTimer() // Stop any existing timer
        timerValue = minutes * 60
        
        if autoStart && timerValue > 0 {
            startTimer()
        }
    }
    
    // Manual timer controls
    func startTimer() {
        guard timerValue > 0 && !isRunning else { return }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    // Private timer tick
    private func tick() {
        if timerValue > 0 {
            timerValue -= 1
        }
    }
    
    // Utility methods for manual adjustments
    func increment(by amount: Int = 1) {
        timerValue += amount
    }
    
    func decrement(by amount: Int = 1) {
        timerValue = max(0, timerValue - amount)
    }
    
    // Formatted time string for display
    var formattedTime: String {
        let minutes = timerValue / 60
        let seconds = timerValue % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Progress as percentage (useful for progress bars)
    func progress(for originalMinutes: Int) -> Double {
        let totalSeconds = originalMinutes * 60
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(timerValue) / Double(totalSeconds))
    }
}

// Notification names for timer events
extension Notification.Name {
    static let AXSharedTimerValueDidChange = Notification.Name("AXSharedTimerValueDidChange")
    static let AXSharedTimerDidComplete = Notification.Name("AXSharedTimerDidComplete")
}
