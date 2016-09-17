//
//  TryTests.swift
//  TypedOperation
//
//  Created by Matt Gadda on 6/1/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import XCTest
@testable import TypedOperation

class TryTests: XCTestCase {
  enum TestErrors : Error {
    case testError
  }

  func testHandleReturn() {
    let tryInt = Try.return(10).handle { error in 20 }
    XCTAssertEqual(try tryInt.get(), 10)
  }

  func testHandleThrow() {
    let tryInt = Try<Int>.throw(TestErrors.testError).handle { error in 20 }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testRescueReturn() {
    let tryInt = Try.return(10).rescue { error in Try.return(20) }
    XCTAssertEqual(try tryInt.get(), 10)
  }

  func testRescueThrow() {
    let tryInt = Try<Int>.throw(TestErrors.testError).rescue { error in Try.return(20) }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testOnSuccessReturn() {
    var result: Int?
    let _ = Try.return(10).onSuccess { value in
      result = value
      return
    }
    XCTAssertEqual(result, 10)
  }

  func testOnSuccessThrow() {
    var result: Int?
    let _ = Try<Int>.throw(TestErrors.testError).onSuccess { value in
      result = value
      return
    }
    XCTAssertNil(result)
  }

  func testOnFailureReturn() {
    var result: Error?
    let _ = Try.return(10).onFailure { error in
      result = error
      return
    }
    XCTAssertNil(result)
  }

  func testOnFailureThrow() {
    var result: Error?
    let _ = Try<Int>.throw(TestErrors.testError).onFailure { error in
      result = error
      return
    }
    XCTAssertNotNil(result)
  }

  func testTryBlockNoError() {
    let tryInt = Try { 10 }
    XCTAssertEqual(try tryInt.get(), 10)
  }

  func testTryBlockError() {
    let tryInt = Try<Int> { throw TestErrors.testError }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testMapReturn() {
    let tryInt = Try.return(10).map { value in value * 2 }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testFlatMapReturn() {
    let tryInt = Try.return(10).flatMap { value in
      Try { value * 2 }
    }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testMapThrow() {
    let tryInt = Try<Int>.throw(TestErrors.testError).map { value in value * 2 }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testFlatMapThrow() {
    let tryInt = Try<Int>.throw(TestErrors.testError).flatMap { value in
      Try { value * 2 }
    }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testFlatMapThrowingBlock() {
    let tryInt = Try.return(10).flatMap { value -> Try<Int> in
      throw TestErrors.testError
    }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testMapThrowingBlock() {
    let tryInt = Try.return(10).map { value -> Try<Int> in
      throw TestErrors.testError
    }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testLiftToOption() {
    XCTAssertNotNil(Try.return(10).liftToOption())
    XCTAssertNil(Try<Int>.throw(TestErrors.testError).liftToOption())
    XCTAssertEqual(Try.return(10).liftToOption(), .some(10))
  }

  // Equatable
  func testEquatable() {
    XCTAssert(Try.return(10) == Try.return(10))    
    XCTAssert(Try.return(10) != Try.return(20))
    XCTAssert(Try.return(10) != Try.throw(TestErrors.testError))
    XCTAssert(Try<Int>.throw(TestErrors.testError) != Try<Int>.throw(TestErrors.testError))
  }
}
