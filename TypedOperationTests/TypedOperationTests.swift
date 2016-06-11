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
  enum TestErrors : ErrorType {
    case TestError
  }

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
      TypedOperation() { () -> Int in
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
      throw TestErrors.TestError
    }
    XCTAssertThrowsError(try op.awaitResult())
  }

  func testFailedOperationThenMap() {
    let op = TypedOperation<Int> {
      throw TestErrors.TestError
    }
    let op2 = op.map { result in
      result * 10
    }
    XCTAssertThrowsError(try op2.awaitResult())
  }

  func testFailedOperationThenFlatMap() {
    let op = TypedOperation<Int> {
      throw TestErrors.TestError
    }
    let op2 = op.flatMap { result in
      TypedOperation(constant: result * 10)
    }
    XCTAssertThrowsError(try op2.awaitResult())
  }

  func testSecondOpFailure() {
    let op = TypedOperation(constant: 10).map { (result) throws -> Int in
      throw TestErrors.TestError
    }
    XCTAssertThrowsError(try op.awaitResult())
  }

  func testFlatMapThrowError() {
    let op = TypedOperation(constant: 10).flatMap { (result) throws -> TypedOperation<Int> in
      throw TestErrors.TestError
    }
    XCTAssertThrowsError(try op.awaitResult())
  }

  func testFlatMapInnerError() {
    let op = TypedOperation(constant: 10).flatMap { (result) -> TypedOperation<Int> in
      return TypedOperation(error: TestErrors.TestError)
    }
    XCTAssertThrowsError(try op.awaitResult())
  }

  func testFlatMapMapWithThrowError() {
    let op = TypedOperation(constant: 10).flatMap { result in
      TypedOperation<Int> { () throws -> Int in
        throw TestErrors.TestError
      }
    }
    XCTAssertThrowsError(try op.awaitResult())
  }

  func testOnSuccess() {
    let exp = expectationWithDescription("onSuccess")
    var testResult: Int?

    TypedOperation(constant: 10).onSuccess { result in
      testResult = result
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(5.0, handler: nil)
    XCTAssertEqual(testResult, .Some(10))
  }

  func testOnSuccessWithChaining() {
    let op = TypedOperation(constant: 10).onSuccess { result in }.map { result in
      result * 2
    }
    XCTAssertEqual(try op.awaitResult(), 20)
  }

  func testOnFailure() {
    let exp = expectationWithDescription("onFailure")
    var testResult: ErrorType?

    TypedOperation<Int>(error: TestErrors.TestError).onFailure { error in
      testResult = error
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(5.0, handler: nil)
    XCTAssertNotNil(testResult)
  }

  func testOnFailureWithChaining() {
    let op = TypedOperation(error: TestErrors.TestError).onFailure { result in }.map { result in
      // This should _not_ execute
      result * 2
    }
    XCTAssertThrowsError(try op.awaitResult())
  }

  func testHandleFailure() {
    let op = TypedOperation<Int>(error: TestErrors.TestError).handle { error in
      return 10
    }
    XCTAssertEqual(try op.awaitResult(), 10)
  }

  func testHandleSuccess() {
    let op = TypedOperation<Int> {
      return 10
    }.handle { (error) -> Int in
      return 20
    }
    XCTAssertEqual(try op.awaitResult(), 10)
  }

  func testRescueFailure() {
    let op = TypedOperation<Int>(error: TestErrors.TestError).rescue { (error) -> TypedOperation<Int> in
      TypedOperation(constant: 10)
    }
    XCTAssertEqual(try op.awaitResult(), 10)
  }

  func testRescueSuccess() {
    let op = TypedOperation<Int> {
      return 10
    }.rescue { (error) -> TypedOperation<Int> in
      TypedOperation(constant: 20)
    }
    XCTAssertEqual(try op.awaitResult(), 10)
  }

  func testJoin() {
    let op = TypedOperation(constant: 10).join(TypedOperation(constant: 20))
    let result = try! op.awaitResult()
    XCTAssert(result == (10, 20))
  }

}
