//
//  AsyncOperationWrapperTests.swift
//  TypedOperation
//
//  Created by Matt Gadda on 6/10/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import XCTest
@testable import TypedOperation

class AsyncOperationAdapterTests: XCTestCase {
  class PiService {
    let queue = OperationQueue()
    let returning: (Float80?, NSError?)

    init(returning: (Float80?, NSError?)) {
      self.returning = returning
    }

    func computePiWith(numDigits precision: Int, callback: @escaping (Float80?, NSError?) -> ()) {
      let op = BlockOperation {
        callback(self.returning.0, self.returning.1)
      }
      queue.addOperation(op)
    }
  }

  func testAsyncOperationAdapterSuccess() {
    let piService = PiService(returning: (3.14159, nil))
    let op = AsyncOperationAdapter { callbackHandler in
      piService.computePiWith(numDigits: 5, callback: callbackHandler)
    }

    let exp = expectation(description: "onSuccess")
    let _ = op.onSuccess { (pi) in
      exp.fulfill()
    }

    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testAsyncOperationAdapterFailure() {
    let piService = PiService(
      returning: (nil, NSError(domain: "An Error", code: 0, userInfo: nil)))

    let op = AsyncOperationAdapter { callbackHandler in
      piService.computePiWith(numDigits: 10, callback: callbackHandler)
    }

    let exp = expectation(description: "onFailure")
    let _ = op.onFailure { (pi) in
      exp.fulfill()
    }

    waitForExpectations(timeout: 5.0, handler: nil)
  }

  // What hapens if the wrapper async computation confusingly returns both
  // a result and error? 
  // Answer: TypedOperation should still resolve to failure.
  func testFailureAndSuccess() {
    let piService = PiService(
      returning: (3.14159, NSError(domain: "An Error", code: 0, userInfo: nil)))

    let op = AsyncOperationAdapter { callbackHandler in
      piService.computePiWith(numDigits: 10, callback: callbackHandler)
    }


    XCTAssertThrowsError(try op.awaitResult())
  }

  func testNoFailureOrSuccess() {
    let piService = PiService(returning: (nil, nil))

    let op = AsyncOperationAdapter { callbackHandler in
      piService.computePiWith(numDigits: 10, callback: callbackHandler)
    }
    XCTAssertThrowsError(try op.awaitResult())
  }
}
