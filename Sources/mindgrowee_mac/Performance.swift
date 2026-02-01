import Foundation

// MARK: - Performance Monitor

@MainActor
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var measurements: [String: [TimeInterval]] = [:]
    
    private init() {}
    
    func measure<T>(name: String, operation: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let diff = CFAbsoluteTimeGetCurrent() - start
        
        Logger.shared.debug("\(name) took \(diff * 1000) ms")
        
        if measurements[name] == nil {
            measurements[name] = []
        }
        measurements[name]?.append(diff)
        
        return result
    }
    
    func asyncMeasure<T>(name: String, operation: @escaping () async -> T) async -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = await operation()
        let diff = CFAbsoluteTimeGetCurrent() - start
        
        Logger.shared.debug("\(name) [async] took \(diff * 1000) ms")
        
        return result
    }
    
    func averageTime(for name: String) -> TimeInterval? {
        guard let times = measurements[name], !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    func printReport() {
        Logger.shared.info("=== Performance Report ===")
        for (name, times) in measurements {
            if let avg = averageTime(for: name) {
                Logger.shared.info("\(name): avg \(avg * 1000) ms (\(times.count) calls)")
            }
        }
    }
}

// MARK: - Memory Cache

class MemoryCache<Key: Hashable, Value> {
    private let cache = NSCache<WrappedKey, WrappedValue>()
    private let lock = NSLock()
    
    init(countLimit: Int = 100) {
        cache.countLimit = countLimit
    }
    
    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: WrappedKey(key))?.value
    }
    
    func set(_ value: Value, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(WrappedValue(value), forKey: WrappedKey(key))
    }
    
    func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: WrappedKey(key))
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
    }
    
    private class WrappedKey: NSObject {
        let key: Key
        
        init(_ key: Key) {
            self.key = key
        }
        
        override var hash: Int {
            key.hashValue
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? WrappedKey else { return false }
            return key == other.key
        }
    }
    
    private class WrappedValue {
        let value: Value
        
        init(_ value: Value) {
            self.value = value
        }
    }
}

// MARK: - Throttler

class Throttler {
    private let queue: DispatchQueue
    private var workItem: DispatchWorkItem?
    private var lastExecution: Date?
    private let minimumDelay: TimeInterval
    
    init(minimumDelay: TimeInterval, queue: DispatchQueue = .main) {
        self.minimumDelay = minimumDelay
        self.queue = queue
    }
    
    func throttle(_ action: @escaping () -> Void) {
        workItem?.cancel()
        
        let now = Date()
        let delay: TimeInterval
        
        if let last = lastExecution, now.timeIntervalSince(last) < minimumDelay {
            delay = minimumDelay - now.timeIntervalSince(last)
        } else {
            delay = 0
        }
        
        workItem = DispatchWorkItem { [weak self] in
            action()
            self?.lastExecution = Date()
        }
        
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

// MARK: - Debouncer

class Debouncer {
    private let queue: DispatchQueue
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(_ action: @escaping () -> Void) {
        workItem?.cancel()
        
        workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

// MARK: - Image Cache

@MainActor
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = MemoryCache<String, Data>(countLimit: 50)
    
    private init() {}
    
    func getImage(for key: String) -> Data? {
        return cache.get(key)
    }
    
    func setImage(_ data: Data, for key: String) {
        cache.set(data, forKey: key)
    }
}

// MARK: - Batch Processor

@MainActor
class BatchProcessor<T> {
    private let processingInterval: TimeInterval
    private var items: [T] = []
    private var timer: Timer?
    private let processHandler: ([T]) -> Void
    
    init(interval: TimeInterval, processHandler: @escaping ([T]) -> Void) {
        self.processingInterval = interval
        self.processHandler = processHandler
    }
    
    func add(_ item: T) {
        items.append(item)
        scheduleProcessing()
    }
    
    func flush() {
        timer?.invalidate()
        processItems()
    }
    
    private func scheduleProcessing() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: processingInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.processItems()
            }
        }
    }
    
    private func processItems() {
        guard !items.isEmpty else { return }
        let batch = items
        items.removeAll()
        processHandler(batch)
    }
}

// MARK: - Lazy Loading

@propertyWrapper
struct Lazy<T> {
    private var storage: T?
    private let builder: () -> T
    
    init(_ builder: @escaping () -> T) {
        self.builder = builder
    }
    
    var wrappedValue: T {
        mutating get {
            if storage == nil {
                storage = builder()
            }
            return storage!
        }
        set {
            storage = newValue
        }
    }
}

// MARK: - Background Task Helper

class BackgroundTask {
    static func run<T: Sendable>(priority: TaskPriority = .userInitiated, operation: @escaping @Sendable () async -> T) async -> T {
        return await Task(priority: priority) {
            return await operation()
        }.value
    }
    
    static func runOnMain<T: Sendable>(operation: @escaping @MainActor () -> T) async -> T {
        return await MainActor.run {
            return operation()
        }
    }
}
