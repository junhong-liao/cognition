import Foundation
import os.log

class Logger {
    static let shared = Logger()
    private let logger: OSLog
    
    private init() {
        self.logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.vision.assistant", category: "VisionAssistant")
    }
    
    func log(_ message: String, type: OSLogType = .default, function: String = #function) {
        os_log("%{public}s: %{public}s", log: logger, type: type, function, message)
        
        #if DEBUG
        print("[\(function)] \(message)")
        #endif
    }
    
    func error(_ error: Error, function: String = #function) {
        os_log("❌ %{public}s: %{public}s", log: logger, type: .error, function, error.localizedDescription)
        
        #if DEBUG
        print("❌ [\(function)] Error: \(error)")
        #endif
    }
    
    func debug(_ message: String, function: String = #function) {
        #if DEBUG
        os_log("🔍 %{public}s: %{public}s", log: logger, type: .debug, function, message)
        print("🔍 [\(function)] \(message)")
        #endif
    }
} 