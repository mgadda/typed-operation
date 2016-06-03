//
//  Try.swift
//  TypedOperation
//
//  Created by Matthew Gadda on 5/23/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation

/// `Try<A>` represents a _synchronous_ computation that may succeed or fail.
public enum Try<A: Equatable> {
  case Return(A)
  case Throw(ErrorType)

  /// Creates a new Try with type parameter `A` equal that of the return value of `f`.
  /// `f` is immediately invoked and either resolves to its return value: `Throw(A)`
  /// or resolves to an error: `Throw(ErrorType)`.
  public init(f: () throws -> A) {
    do {
      self = Return(try f())
    } catch {
      self = Throw(error)
    }
  }

  /// Invoke `f` with underlying value of type `A` if and only if target has
  /// resovled to `Return(A)`. The return value of `f` becomes a new instance of
  /// `Try<B>`.
  /// If target resolved to `Throw(ErrorType)`, `f` is not invoked and the
  /// is error is propogated into the returned `Try<B>` instance.
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

  /// Invoke `f` with underlying value of type `A` if and only if target has
  /// resovled to `Return(A)`. The return value of `f` is returned from `flatMap`.
  /// If target resolved to `Throw(ErrorType)`, `f` is not invoked and the
  /// is error is propogated into the returned `Try<B>` instance.
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

  /// Invoke `f` with the underlying error if target resolved to `Throw`.
  /// Use this method to recover from a failed computation.
  public func handle(f: ErrorType -> A) -> Try<A> {
    // TODO: return Try<B> where B >: A
    switch self {
    case Return(_):
      return self
    case let Throw(error):
      return Try { f(error) }
    }
  }

  /// Invoke `f` with the underlying error if target resolved to `Throw`.
  /// Use this method to recover from a failed computation.
  public func rescue(f: ErrorType -> Try<A>) -> Try<A> {
    // TODO: return Try<B> where B >: A
    switch self {
    case Return(_):
      return self
    case let Throw(error):
      return f(error)
    }
  }

  /// Invoke `f` with the underlying result if target resolved to `Return`.
  /// Use this method for side-effects.
  public func onSuccess(f: A -> ()) -> Try<A> {
    switch self {
    case let Return(a):
      f(a)
    case Throw(_):
      break
    }
    return self
  }

  /// Invoke `f` with the underlying result if target resolved to `Return`.
  /// Use this method for side-effects.
  public func onFailure(f: ErrorType -> ()) -> Try<A> {
    switch self {
    case Return(_): break
    case let Throw(error):
      f(error)

    }
    return self
  }

  /// Force target to return the underlying value if target resolved to `Return`.
  /// If target resolved to an error, `get()` rethrows this error.
  public func get() throws -> A {
    switch self {
    case let Return(a):
      return a
    case let Throw(error):
      throw error
    }
  }

  /// Convert target into an `Optional<A>`. If target resolved to `Throw`
  /// return `some(underlying)`, otherwise return `some`.
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

/// Implements Equatable. If `lhs` and `rhs` _both_ resolve to `Return` _and_
/// their underlying values are equal. Otherwise, `lhs` and `rhs` are not
/// considered equal.
/// Because `ErrorType` does not conform to `Equatable`, it is not possible to
/// equate two failed `Try` instances.
public func ==<A: Equatable>(lhs: Try<A>, rhs: Try<A>) -> Bool {
  switch (lhs, rhs) {
  case let (.Return(left), .Return(right)):
    return left == right
  default:
    return false
  }
}
