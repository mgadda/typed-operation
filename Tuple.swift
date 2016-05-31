//
//  Tuple.swift
//  TypedOperation
//
//  Created by Matt Gadda on 5/30/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation

public struct Tuple2<T: Equatable, U: Equatable>: Equatable {
  let value: (T, U)
  init(_ first: T, _ second: U) {
    value = (first, second)
  }
  var _0: T { return value.0 }
  var _1: U { return value.1 }
}

public func ==<T: Equatable, U: Equatable>(lhs: Tuple2<T,U>, rhs: Tuple2<T, U>) -> Bool {
  return lhs.value.0 == rhs.value.0 && lhs.value.1 == rhs.value.1
}

public func ~=<T: Equatable, U: Equatable>(pattern: Tuple2<T, U>, predicate: Tuple2<T, U>) -> Bool {
  switch predicate.value {
  case (pattern._0, pattern._1):
    return true
  default:
    return false
  }
}


public struct Tuple3<T: Equatable, U: Equatable, V: Equatable>: Equatable {
  let value: (T, U, V)
  init(_ first: T, _ second: U, _ third: V) {
    value = (first, second, third)
  }
  var _0: T { return value.0 }
  var _1: U { return value.1 }
  var _2: V { return value.2 }
}

public func ==<T: Equatable, U: Equatable, V: Equatable>(lhs: Tuple3<T,U,V>, rhs: Tuple3<T, U, V>) -> Bool {
  return lhs.value.0 == rhs.value.0 &&
    lhs.value.1 == rhs.value.1 &&
    lhs.value.2 == rhs.value.2
}

public func ~=<T: Equatable, U: Equatable, V: Equatable>(pattern: Tuple3<T, U ,V>, predicate: Tuple3<T, U, V>) -> Bool {
  switch predicate.value {
  case (pattern._0, pattern._1, pattern._2):
    return true
  default:
    return false
  }
}
