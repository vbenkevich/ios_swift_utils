//
//  SpinLock.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//


import Foundation

typealias SpinLock = os_unfair_lock

extension SpinLock {

    mutating func lock() {
        os_unfair_lock_lock(&self)
    }

    mutating func unlock() {
        os_unfair_lock_unlock(&self)
    }
}
