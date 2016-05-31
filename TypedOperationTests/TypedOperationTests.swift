//
//  TypedOperationTests.swift
//  TypedOperationTests
//
//  Created by Matt Gadda on 5/29/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import XCTest
@testable import TypedOperation

class TypedOperationTests: XCTestCase {
  class TestError : ErrorType {}

  override func setUp() {
      super.setUp()
      // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()
  }

  func testConst() {
    let constOp = TypedOperation(constant: 10)
//    print(constOp.finished)
//    print(constOp.result)
    let result = try! constOp.awaitResult()

    XCTAssert(result == 10)
  }
  
  func testFlatMap() {
    let op = TypedOperation(constant: 10).flatMap { (result) -> TypedOperation<Int> in
      TypedOperation() {
        // Increases liklihood of race condition, if present
        sleep(2)
        return result * 10
      }
    }
    XCTAssert(try op.awaitResult() == 100)
  }

  func testMap() {
    let op = TypedOperation(constant: 10).map { result -> Int in
      // Increases liklihood of race condition, if present
      sleep(2)
      return result * 10
    }
    XCTAssert(try op.awaitResult() == 100)
  }

  func testFlatMapMap() {
    let op = TypedOperation(constant: 10).flatMap { result in
      TypedOperation(constant: 20).map({ inner in
        result * inner
      })
    }
    XCTAssert(try op.awaitResult() == 200)
  }

  func testFailedOperation() {
    let op = TypedOperation<Int> {
      throw TestError()
    }
    XCTAssertThrowsError(try op.awaitResult())
  }

  func testFailedOperationThenMap() {
    let op = TypedOperation<Int> {
      throw TestError()
    }
    let op2 = op.map { result in
      result * 10
    }
    XCTAssertThrowsError(try op2.awaitResult())
  }
}
