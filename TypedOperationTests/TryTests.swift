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
  enum TestErrors : ErrorType {
    case TestError
  }

  func testHandleReturn() {
    let tryInt = Try.Return(10).handle { error in 20 }
    XCTAssertEqual(try tryInt.get(), 10)
  }

  func testHandleThrow() {
    let tryInt = Try<Int>.Throw(TestErrors.TestError).handle { error in 20 }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testRescueReturn() {
    let tryInt = Try.Return(10).rescue { error in Try.Return(20) }
    XCTAssertEqual(try tryInt.get(), 10)
  }

  func testRescueThrow() {
    let tryInt = Try<Int>.Throw(TestErrors.TestError).rescue { error in Try.Return(20) }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testOnSuccessReturn() {
    var result: Int?
    let _ = Try.Return(10).onSuccess { value in
      result = value
      return
    }
    XCTAssertEqual(result, 10)
  }

  func testOnSuccessThrow() {
    var result: Int?
    let _ = Try<Int>.Throw(TestErrors.TestError).onSuccess { value in
      result = value
      return
    }
    XCTAssertNil(result)
  }

  func testOnFailureReturn() {
    var result: ErrorType?
    let _ = Try.Return(10).onFailure { error in
      result = error
      return
    }
    XCTAssertNil(result)
  }

  func testOnFailureThrow() {
    var result: ErrorType?
    let _ = Try<Int>.Throw(TestErrors.TestError).onFailure { error in
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
    let tryInt = Try<Int> { throw TestErrors.TestError }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testMapReturn() {
    let tryInt = Try.Return(10).map { value in value * 2 }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testFlatMapReturn() {
    let tryInt = Try.Return(10).flatMap { value in
      Try { value * 2 }
    }
    XCTAssertEqual(try tryInt.get(), 20)
  }

  func testMapThrow() {
    let tryInt = Try<Int>.Throw(TestErrors.TestError).map { value in value * 2 }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testFlatMapThrow() {
    let tryInt = Try<Int>.Throw(TestErrors.TestError).flatMap { value in
      Try { value * 2 }
    }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testFlatMapThrowingBlock() {
    let tryInt = Try.Return(10).flatMap { value -> Try<Int> in
      throw TestErrors.TestError
    }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testMapThrowingBlock() {
    let tryInt = Try.Return(10).map { value -> Try<Int> in
      throw TestErrors.TestError
    }
    XCTAssertThrowsError(try tryInt.get())
  }

  func testLiftToOption() {
    XCTAssertNotNil(Try.Return(10).liftToOption())
    XCTAssertNil(Try<Int>.Throw(TestErrors.TestError).liftToOption())
    XCTAssertEqual(Try.Return(10).liftToOption(), .Some(10))
  }

  // Equatable
  func testEquatable() {
    XCTAssert(Try.Return(10) == Try.Return(10))    
    XCTAssert(Try.Return(10) != Try.Return(20))
    XCTAssert(Try.Return(10) != Try.Throw(TestErrors.TestError))
    XCTAssert(Try<Int>.Throw(TestErrors.TestError) != Try<Int>.Throw(TestErrors.TestError))
  }
}
