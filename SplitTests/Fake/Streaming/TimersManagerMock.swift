//
//  TimersManagerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class TimersManagerMock: TimersManager {

    private var timersAdded = Set<TimerName>()
    private var timersCancelled = Set<TimerName>()
    private var expectations = [TimerName: XCTestExpectation]()

    func add(timer: TimerName, task: CancellableTask) {
        _ = DispatchQueue.test.sync {
            self.timersAdded.insert(timer)
        }
        if let exp = expectations[timer] {
            exp.fulfill()
        }
    }

    func cancel(timer: TimerName) {
        _ = DispatchQueue.test.sync {
            self.timersCancelled.insert(timer)
        }
    }

    func timerIsAdded(timer: TimerName) -> Bool {
        var result = false
        DispatchQueue.test.sync {
            result = self.timersAdded.contains(timer)
        }
        return result
    }

    func timerIsCancelled(timer: TimerName) -> Bool {
        var result = false
        DispatchQueue.test.sync {
            result = self.timersCancelled.contains(timer)
        }
        return result
    }

    func addExpectationFor(timer: TimerName, expectation: XCTestExpectation) {
        expectations[timer] = expectation
    }

    func reset(timer: TimerName? = nil) {
        DispatchQueue.test.sync {
            if let timer = timer {
                self.timersAdded.remove(timer)
                self.timersCancelled.remove(timer)
            } else {
                self.timersAdded.removeAll()
                self.timersCancelled.removeAll()
            }
        }
    }

    func destroy() {
    }
}

