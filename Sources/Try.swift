//
//  Try.swift
//  TypedOperation
//
//  Created by Matthew Gadda on 5/23/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation

public enum Try<A: Equatable> {
  case Return(A)
  case Throw(ErrorType)

  init(f: () throws -> A) {
    do {
      self = Return(try f())
    } catch {
      self = Throw(error)
    }
  }

  func map<B>(f: (A) throws -> B) -> Try<B> {
    switch self {
    case let Return(a):
      do {
        let b = try f(a)
        return .Return(b)
      } catch {
        let fail: Try<B> = .Throw(error)
        return fail
      }
    case let Throw(error):
      return .Throw(error)
    }
  }

  func flatMap<B>(f: A throws -> Try<B>) -> Try<B> {
    switch self {
    case let Return(a):
      do {
        return try f(a)
      } catch {
        let fail: Try<B> = .Throw(error)
        return fail
      }
    case let Throw(error):
      return .Throw(error)
    }
  }

  // TODO: B >: A
  func handle<B>(f: ErrorType -> B) -> Try<B> {
    switch self {
    case Return(_):
      //return self // this would be possible if B >: A
      return map { $0 as! B } // instead the compiler asserts nothing and we leave it to the runtime

    case let Throw(error):
      return Try<B> { f(error) }
    }
  }

  // TODO: B >: A
  func rescue<B>(f: ErrorType -> Try<B>) -> Try<B> {
    switch self {
    case Return(_):
      return map { $0 as! B }
    case let Throw(error):
      return f(error)
    }
  }

  func onSuccess(f: A -> ()) -> Try<A> {
    switch self {
    case let Return(a):
      f(a)
    case Throw(_): break
    }
    return self
  }

  func onFailure(f: ErrorType -> ()) -> Try<A> {
    switch self {
    case Return(_): break
    case let Throw(error):
      f(error)

    }
    return self
  }

  func get() throws -> A {
    switch self {
    case let Return(a):
      return a
    case let Throw(error):
      throw error
    }
  }

  func liftToOption() -> A? {
    switch self {
    case let Return(a):
      return .Some(a)
    default:
      return .None
    }
  }
}

extension Try: Equatable {}

public func ==<A: Equatable>(lhs: Try<A>, rhs: Try<A>) -> Bool {
  switch (lhs, rhs) {
  case let (.Return(left), .Return(right)):
    return left == right
  default:
    return false
  }
}
