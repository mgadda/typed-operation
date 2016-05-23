//
//  Try.swift
//  TypedOperation
//
//  Created by Matthew Gadda on 5/23/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation

enum Try<A> {
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
