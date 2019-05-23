//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation


/// protocol for all pthread_lock and os_lock warappers
public protocol Lock {

    /// acquire the lock
    ///
    func lock()

    /// release the lock
    ///
    func unlock()

    /// try acquire the lock
    ///
    /// - Returns: true if lock has been acquired
    func tryLock() -> Bool
}


public extension Lock {

    /// Execute block under the lock
    ///
    /// - Parameter block: block to performing
    /// - Returns: block's result
    /// - Throws: rethrows block's error
    func sync<T>(_ block: () throws -> T) throws -> T {
        lock()
        defer {
            unlock()
        }

        return try block()
    }
}


/// os_unfair_lock wrapper (class can be safly copied and captured)
public class UnfairLock: Lock {

    private var _lock = os_unfair_lock()

    public func lock() {
        os_unfair_lock_lock(&_lock)
    }

    public func unlock() {
        os_unfair_lock_unlock(&_lock)
    }

    public func tryLock() -> Bool {
        return os_unfair_lock_trylock(&_lock)
    }
}


/// pthread_mutexattr_t wrapper (class can be safly copied and captured)
public class Mutex: Lock {

    /// initialize the new Mutex instance
    ///
    /// - Parameter recursive: is lock recursive or not
    public init(recursive: Bool = true) {
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&attr, recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_NORMAL)
        pthread_mutex_init(&_lock, &attr)
    }

    deinit {
        pthread_mutex_destroy(&_lock)
    }

    private var _lock = pthread_mutex_t()

    public func lock() {
        pthread_mutex_lock(&_lock)
    }

    public func unlock() {
        pthread_mutex_unlock(&_lock)
    }

    public func tryLock() -> Bool {
        return pthread_mutex_trylock(&_lock) == 0
    }
}


public extension Mutex {

    /// creates recursive pthread_mutexattr_t wrapper (class can be safly copied and captured)
    ///
    /// - Returns: Mutex
    static func recursive() -> Mutex {
        return Mutex(recursive: true)
    }

    /// creates not recursive pthread_mutexattr_t wrapper (class can be safly copied and captured)
    ///
    /// - Returns: Mutex
    static func normal() -> Mutex {
        return Mutex(recursive: false)
    }
}


/// pthread_rwlock_t wrapper (class can be safly copied and captured)
public class RwLock {

    private var _lock = pthread_rwlock_t()

    /// initialize the new RwLock instance
    public init() {
        pthread_rwlock_init(&_lock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&_lock)
    }

    /// lock for reading
    public var read: Lock {
        return Read(rwLock: self)
    }

    /// lock for writing
    public var write: Lock {
        return Write(rwLock: self)
    }


    struct Read: Lock {
        let rwLock: RwLock

        func lock() {
            pthread_rwlock_rdlock(&rwLock._lock)
        }

        func unlock() {
            pthread_rwlock_unlock(&rwLock._lock)
        }

        func tryLock() -> Bool {
            return pthread_rwlock_tryrdlock(&rwLock._lock) == 0
        }
    }


    struct Write: Lock {
        let rwLock: RwLock

        func lock() {
            pthread_rwlock_wrlock(&rwLock._lock)
        }

        func unlock() {
            pthread_rwlock_unlock(&rwLock._lock)
        }

        func tryLock() -> Bool {
            return pthread_rwlock_trywrlock(&rwLock._lock) == 0
        }
    }
}


/// OSSpinLock wrapper
/// it can cause priority inverstion issues
@available(*, deprecated, message: "Use UnfairLock() instead")
class SpinLock: Lock {

    private var _lock = OSSpinLock()

    func lock() {
        OSSpinLockLock(&_lock)
    }

    func unlock() {
        OSSpinLockUnlock(&_lock)
    }

    func tryLock() -> Bool {
        return OSSpinLockTry(&_lock)
    }
}
