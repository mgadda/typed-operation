//
//  Try.swift
//  TypedOperation
//
//  Created by Matthew Gadda on 5/23/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation

/// `Try<A>` represents a _synchronous_ computation that may succeed or fail.
public enum Try<A> {
  case `return`(A)
  case `throw`(Error)

  /// Creates a new Try with type parameter `A` equal that of the return value of `f`.
  /// `f` is immediately invoked and either resolves to its return value: `Throw(A)`
  /// or resolves to an error: `Throw(ErrorType)`.
  public init(f: () throws -> A) {
    do {
      self = Try.`return`(try f())
    } catch {
      self = Try.`throw`(error)
    }
  }

  /// Invoke `f` with underlying value of type `A` if and only if target has
  /// resovled to `Return(A)`. The return value of `f` becomes a new instance of
  /// `Try<B>`.
  /// If target resolved to `Throw(ErrorType)`, `f` is not invoked and the
  /// is error is propogated into the returned `Try<B>` instance.
  public func map<B>(_ f: (A) throws -> B) -> Try<B> {
    switch self {
    case let .return(a):
      do {
        let b = try f(a)
        return .return(b)
      } catch {
        let fail: Try<B> = .throw(error)
        return fail
      }
    case let .throw(error):
      return .throw(error)
    }
  }

  /// Invoke `f` with underlying value of type `A` if and only if target has
  /// resovled to `Return(A)`. The return value of `f` is returned from `flatMap`.
  /// If target resolved to `Throw(ErrorType)`, `f` is not invoked and the
  /// is error is propogated into the returned `Try<B>` instance.
  public func flatMap<B>(_ f: (A) throws -> Try<B>) -> Try<B> {
    switch self {
    case let .return(a):
      do {
        return try f(a)
      } catch {
        let fail: Try<B> = .throw(error)
        return fail
      }
    case let .throw(error):
      return .throw(error)
    }
  }

  /// Invoke `f` with the underlying error if target resolved to `Throw`.
  /// Use this method to recover from a failed computation.
  public func handle(_ f: @escaping (Error) -> A) -> Try<A> {
    // TODO: return Try<B> where B >: A
    switch self {
    case .return(_):
      return self
    case let .throw(error):
      return Try { f(error) }
    }
  }

  /// Invoke `f` with the underlying error if target resolved to `Throw`.
  /// Use this method to recover from a failed computation.
  public func rescue(_ f: (Error) -> Try<A>) -> Try<A> {
    // TODO: return Try<B> where B >: A
    switch self {
    case .return(_):
      return self
    case let .throw(error):
      return f(error)
    }
  }

  /// Invoke `f` with the underlying result if target resolved to `Return`.
  /// Use this method for side-effects.
  public func onSuccess(_ f: (A) -> ()) -> Try<A> {
    switch self {
    case let .return(a):
      f(a)
    case .throw(_):
      break
    }
    return self
  }

  /// Invoke `f` with the underlying result if target resolved to `Return`.
  /// Use this method for side-effects.
  public func onFailure(_ f: (Error) -> ()) -> Try<A> {
    switch self {
    case .return(_): break
    case let .throw(error):
      f(error)

    }
    return self
  }

  /// Force target to return the underlying value if target resolved to `Return`.
  /// If target resolved to an error, `get()` rethrows this error.
  public func get() throws -> A {
    switch self {
    case let .return(a):
      return a
    case let .throw(error):
      throw error
    }
  }

  /// Convert target into an `Optional<A>`. If target resolved to `Throw`
  /// return `some(underlying)`, otherwise return `some`.
  public func liftToOption() -> A? {
    switch self {
    case let .return(a):
      return .some(a)
    default:
      return .none
    }
  }
}

/// If `lhs` and `rhs` _both_ resolve to `Return` _and_
/// their underlying values are equal. Otherwise, `lhs` and `rhs` are not
/// considered equal.
/// Because `ErrorType` does not conform to `Equatable`, it is not possible to
/// equate two failed `Try` instances.
public func ==<A: Equatable>(lhs: Try<A>, rhs: Try<A>) -> Bool {
  switch (lhs, rhs) {
  case let (.return(left), .return(right)):
    return left == right
  default:
    return false
  }
}

public func !=<A: Equatable>(lhs: Try<A>, rhs: Try<A>) -> Bool {
  return !(lhs == rhs)
}
