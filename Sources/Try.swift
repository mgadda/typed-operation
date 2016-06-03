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

  public init(f: () throws -> A) {
    do {
      self = Return(try f())
    } catch {
      self = Throw(error)
    }
  }

  public func map<B>(f: (A) throws -> B) -> Try<B> {
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

  public func flatMap<B>(f: A throws -> Try<B>) -> Try<B> {
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

  // TODO: return Try<B> where B >: A
  public func handle(f: ErrorType -> A) -> Try<A> {
    switch self {
    case Return(_):
      return self
    case let Throw(error):
      return Try { f(error) }
    }
  }

  // TODO: return Try<B> where B >: A
  public func rescue(f: ErrorType -> Try<A>) -> Try<A> {
    switch self {
    case Return(_):
      return self
    case let Throw(error):
      return f(error)
    }
  }

  public func onSuccess(f: A -> ()) -> Try<A> {
    switch self {
    case let Return(a):
      f(a)
    case Throw(_):
      break
    }
    return self
  }

  public func onFailure(f: ErrorType -> ()) -> Try<A> {
    switch self {
    case Return(_): break
    case let Throw(error):
      f(error)

    }
    return self
  }

  public func get() throws -> A {
    switch self {
    case let Return(a):
      return a
    case let Throw(error):
      throw error
    }
  }

  public func liftToOption() -> A? {
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
