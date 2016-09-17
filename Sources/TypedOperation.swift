//
//  TypedOperation.swift
//  TypedOperation
//
//  Created by Matthew Gadda on 5/23/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation


/// Adds type safety and implicit dependencies between NSOperations.
/// A TypedOperation encapsulates a typed computation which
/// executes asynchronously.
open class TypedOperation<A>: Operation {
  var result: Try<A>? = nil

  let computation: () -> Try<A>
  var queue: OperationQueue

  static func makeQueue() -> OperationQueue {
    let q = OperationQueue()
    q.name = "TypedOperation<\(A.self)> " + Unmanaged.passUnretained(self as AnyObject).toOpaque().debugDescription
    return q
  }

  fileprivate static var defaultQueue: OperationQueue {
    return makeQueue()
  }

  /// Immediately enqueue the block defined by f for execution.
  public init(f: @escaping () throws -> A) {
    queue = TypedOperation.makeQueue()
    computation = {
      do {
        return .return(try f())
      } catch {
        return .throw(error)
      }
    }
    super.init()
    queue.addOperation(self)
  }

  /// Create a TypedOperation that will resolve to a constant value.
  public convenience init(constant: A) {
    self.init() { .return(constant) }
  }

  /// Create a TypedOperation that will resolve to an error.
  public convenience init(error: Error) {
    self.init() { .throw(error) }
  }

  fileprivate init(queue: OperationQueue, constant: A) {
    self.queue = queue
    computation = {
      return .return(constant)
    }
    super.init()
    // Do not enqueue operation, call will handle this
  }

  fileprivate init(queue: OperationQueue, _ f: @escaping () throws -> A) {
    self.queue = queue
    computation = {
      do {
        return .return(try f())
      } catch {
        return .throw(error)
      }
    }
    super.init()
    // Do not enqueue operation, caller will handle this
  }

  /// `f` directly becomes the computation of this `TypedOperation<A>`
  /// Operation runs in its own queue and is immediately enqueued.
  internal init(tryBlock: @escaping () -> Try<A>) {
    queue = TypedOperation.makeQueue()
    computation = tryBlock
    super.init()
    queue.addOperation(self)
  }

  fileprivate init(queue: OperationQueue, tryBlock: @escaping () -> Try<A>) {
    self.queue = queue
    computation = tryBlock

    super.init()
    // Do not enqueue operation, caller will handle this
  }

  /// Execute `block` and flatten its result into `self.result`.
  fileprivate init(queue: OperationQueue, typedOpBlock: @escaping () -> TypedOperation<A>) {
    self.queue = queue

    computation = {
      let op = typedOpBlock()
      op.waitUntilFinished()

      return op.result!
    }
    super.init()
  }

  override open func main() {
    result = computation()
  }


  /// Waits on the operation until it transitions to the finished
  /// state. That is, until the finished property is true.
  ///
  /// This is probably not the method you're looking for. If you use this method
  /// in the main thread, your user interface will _stop responding_ until this
  /// method returns.
  ///
  /// Prefer asynchronous methods such as `onSuccess()`, `onFailure()`,
  /// `map()` and flatMap()`.
  open func awaitResult() throws -> A {
    waitUntilFinished()
    return try result!.get() // assumes A always succeeds (not correct)
  }


  /// Join the results of the target operation and the argument operation.
  open func join<B>(_ operation: TypedOperation<B>) -> TypedOperation<(A, B)> {
    // Make new typed operation which is dependent up on these two operations
    let toAB = TypedOperation<(A, B)>(queue: queue) {
      self.result!.flatMap({ (aResult) in
        operation.result!.map({ (aResult, $0) })
      })
    }
    toAB.addDependency(self)
    toAB.addDependency(operation)
    queue.addOperation(toAB)
    return toAB
  }

  /// Asynchronously invoke `f` on target if target resolves successfully.
  /// `f` is not invoked if target fails.
  /// Use this method for its side effects.
  open func onSuccess(_ f: @escaping (A) -> ()) -> TypedOperation<A> {
    // design question: should a new TypedOperation<A> (same A) be returned?
    // the result would be that invocations of map on the result must occur
    // after (i.e. depend upon) the onSuccess computation, even though it's
    // used only for side effects.
    // if we return self here, then potentially two blocks may execute at the
    // same time.

    let op = BlockOperation {
      let _ = self.result!.onSuccess(f)
    }
    op.addDependency(self)
    queue.addOperation(op)
    return self

  }

  /// Asynchronously invoke `f` on target if target resolve to an error.
  /// `f` is not invoked if target succeeds.
  /// Use this method for its side effects.
  open func onFailure(_ f: @escaping (Error) -> ()) -> TypedOperation<A> {
    let op = BlockOperation {
      let _ = self.result!.onFailure(f)
    }
    op.addDependency(self)
    queue.addOperation(op)
    return self
  }

  /// Asynchronously invoke `f` if and only if target resovles to an error.
  /// Use this method to recover from an error by returning a new value
  /// of type A.
  open func handle(_ f: @escaping (Error) -> A) -> TypedOperation<A> {
    // TODO: return TypedOperation<B> where B >: A
    let handleOp = TypedOperation<A>(queue: queue) {
      self.result!.handle(f)
    }
    handleOp.addDependency(self)
    queue.addOperation(handleOp)
    return handleOp
  }

  /// Asynchronously invoke `f` if and only if target resovles to an error.
  /// Use this method to recover from an error by returning a new
  /// `TypedOperation<A>`.
  open func rescue(_ f: @escaping (Error) -> TypedOperation<A>) -> TypedOperation<A> {
    // TODO: return TypedOperation<B> where B >: A
    return transform { (result) -> TypedOperation<A> in
      switch result {
      case let .throw(error):
        return f(error)
      case .return:
        return self
      }
    }
  }

  /// Asynchronously invoke `f` on target if and only if the target
  /// resolves successfully.
  open func map<B>(_ f: @escaping (A) throws -> B) -> TypedOperation<B> {
    return transform({ (result) -> TypedOperation<B> in
      switch result {
      case let .return(a):
        // This operation _must_ not enqueue in the same queue as self. Otherwise deadlock is all but guaranteed.
        return TypedOperation<B> {
          try f(a)
        }
      case let .throw(error):
        return TypedOperation<B>(error: error)
      }
    })
  }

  /// Asynchronously invoke `f` on target if and only if the target
  /// resolves successfully.
  open func flatMap<B>(_ f: @escaping (A) throws -> TypedOperation<B>) -> TypedOperation<B> {
    return transform { (result) -> TypedOperation<B> in
      switch result {
      case let .return(a):
        do {
          return try f(a)
        } catch {
          return TypedOperation<B>(error: error)
        }
      case let .throw(error):
        return TypedOperation<B>(error: error)
      }
    }
  }

  /// Invoke `f` with the results of this operation, once they're
  /// available. The `TypedOperation<B>` returned by `f` must be scheduled
  /// in distinct queue than self.
  func transform<B>(_ f: @escaping (Try<A>) -> TypedOperation<B>) -> TypedOperation<B> {
    let toB = TypedOperation<B>(queue: queue) {
      f(self.result!)
    }
    toB.addDependency(self)
    queue.addOperation(toB)
    return toB
  }
}

public enum TypedOperationError: Error {
  case unknownError
}

