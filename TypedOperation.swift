//
//  TypedOperation.swift
//  TypedOperation
//
//  Created by Matthew Gadda on 5/23/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation


/**
 Adds type safety and implicit dependencies between NSOperations
 */
class TypedOperation<A>: NSOperation {
  var result: Try<A>? = nil

  let computation: () -> Try<A>
  let queue: NSOperationQueue

  private static var defaultQueue: NSOperationQueue {
    let q = NSOperationQueue()
    q.name = "TypedOperation"
    return q
  }

  // A typed operation that resolves to `constant`
  init(constant: A) {
    self.queue = TypedOperation.defaultQueue
    computation = {
      return .Return(constant)
    }
    super.init()
    self.queue.addOperation(self)
  }

  private init(queue: NSOperationQueue, constant: A) {
    self.queue = queue
    computation = {
      return .Return(constant)
    }
    super.init()
    // Do not enqueue operation, call will handle this
  }

  /**
   Immediately enqueue the block defined by f for execution.
   */
  init(f: () throws -> A) {
    self.queue = NSOperationQueue()
    computation = {
      do {
        return .Return(try f())
      } catch {
        return .Throw(error)
      }
    }
    super.init()
    self.queue.addOperation(self)
  }

  /**
   The effect of passing a queue into the constructor is that
   the instantiated TypedOperation will not automatically enqueue
   itself. It is up to the caller (one with private access, such
   as instance methods of a calling TypedOperation) to enqueue
   the operation after construction (and typically after
   dependencies have been configured).
   We still pass the queue in if this operation becomes a dependent operation
   of another operation (as is the case with calls to `TypedOperation<T>.map()`).
   */
  private init(queue: NSOperationQueue, _ f: () throws -> A) {
    self.queue = queue
    computation = {
      do {
        return .Return(try f())
      } catch {
        return .Throw(error)
      }
    }
    super.init()
    // Do not enqueue operation, caller will handle this
  }


  /**
   Create a TypedOperation from a block. Useful for implementing flatMap.
   Caller is expected to enqueue instantiated operation.
   @deprecated
   */
  private init(queue: NSOperationQueue, tryOp: () -> Try<TypedOperation<A>>) {
    self.queue = queue
    computation = {
      tryOp().flatMap { $0.result! }
    }

    super.init()
    // Do not enqueue operation, caller will handle this
  }

  private init(queue: NSOperationQueue, tryBlock: () -> Try<A>) {
    self.queue = queue
    computation = tryBlock

    super.init()
    // Do not enqueue operation, caller will handle this
  }



  // Create a TypedOperation that is an immediate failure
  init(queue: NSOperationQueue, error: ErrorType) {
    self.queue = queue
    computation = { .Throw(error) }
    super.init()
  }

  // Flatten this into the `TypedOperation<A>` returned by block. Used by
  // `TypedOperation<A>.flatMap`.
  // BUG: this operation _must_ depend upon the operation returned by block()
  // without which, it will attempt to access block()'s result before
  /* private */ init(queue: NSOperationQueue, block: () -> TypedOperation<A>) {
    self.queue = queue
    computation = {
      block().result!
    }
    super.init()
  }

  override func main() {
    result = computation()
  }

  //  /**
  //   If result of target succeeds, f is invoked with result
  //   If result does not succeed, f is not invoked.
  //   */
  //  func map<B>(f: (A) -> B) -> TypedOperation<B> {
  //    let toB = TypedOperation<B>(queue: queue) {
  //      // result must have value by the time this operation executes
  //      // Luckily, this is guaranteed by NSOperation.addDependency.
  //      let nextResult = self.result!.map { f($0) }
  //      // This logic is probably not correct
  //      switch nextResult {
  //      case let .Return(b):
  //        return b
  //      case let .Throw(err):
  //        throw err
  //      }
  //    }
  //
  //    toB.addDependency(self)
  //    queue.addOperation(toB)
  //    return toB
  //  }
  //
  //
  //  func flatMap<B>(f: A -> TypedOperation<B>) -> TypedOperation<B> {
  //    let op = {
  //      self.result!.map { f($0) }
  //    }
  //    let toB = TypedOperation<B>(queue: queue, tryOp: op)
  //    toB.addDependency(self)
  //    queue.addOperation(toB)
  //    return toB
  //  }


  /**
   Waits on the operation until it transitions to the finished
   state. That is, until the finished property is true.
   This is probably not the method you're looking for.
   */
  func awaitResult() throws -> A {
    waitUntilFinished()
    return try result!.get() // assumes A always succeeds (not correct)
  }

  /**
   Join the results of the target operation and the argument operation.
   TODO(mgadda): determine how to manage error states for joined operations
   TODO(mgadda): determine if this should be static
   */
  func join<B>(operation: TypedOperation<B>) -> TypedOperation<(A, B)> {
    // Make new typed operation which is dependent up on these two operations
    let toAB = TypedOperation<(A, B)>(queue: queue) {
      self.result!.flatMap({ (aResult) in
        operation.result!.map({ (bResult) in
          (aResult, bResult)
        })
      })
      //return try (self.result!.get(), operation.result!.get())
    }
    toAB.addDependency(self)
    toAB.addDependency(operation)
    queue.addOperation(toAB)
    return toAB
  }

  // Use this method for its side effects.
  func onSuccess(f: A -> ()) -> TypedOperation<A> {
    // design question: should a new TypedOperation<A> (same A) be returned?
    // the result would be that invocations of map on the result must occur
    // after (i.e. depend upon) the onSuccess computation, even though it's
    // used only for side effects.
    // if we return self here, then potentially two blocks may execute at the
    // same time.

    let op = NSBlockOperation {
      self.result!.onSuccess(f)
    }
    op.addDependency(self)
    queue.addOperation(op)
    return self

  }

  func onFailure(f: ErrorType -> ()) -> TypedOperation<A> {
    let op = NSBlockOperation {
      self.result!.onFailure(f)
    }
    op.addDependency(self)
    queue.addOperation(op)
    return self
  }

  func handle<B>(f: ErrorType -> B) -> TypedOperation<B> {
    let handleOp = TypedOperation<B>(queue: queue) {
      try self.result!.handle(f).get()
    }
    handleOp.addDependency(self)
    queue.addOperation(handleOp)
    return handleOp
  }

  func rescue<B>(f: ErrorType -> TypedOperation<B>) -> TypedOperation<B> {
    let rescueOp = {
      self.result!.handle(f)
    }
    let toB = TypedOperation<B>(queue: queue, tryOp: rescueOp)
    toB.addDependency(self)
    queue.addOperation(toB)
    return toB
  }

  func map2<B>(f: A -> B) -> TypedOperation<B> {
    return transform({ (result) -> TypedOperation<B> in
      switch result {
      case let .Return(a):
        // psuedo-code:
        // become
        return TypedOperation<B>(queue: self.queue) {
          f(a)
        }
      case let .Throw(error):
        return TypedOperation<B>(queue: self.queue, error: error)
      }
    })
  }

  func flatMap2<B>(f: A -> TypedOperation<B>) -> TypedOperation<B> {
    return transform { (result) -> TypedOperation<B> in
      switch result {
      case let .Return(a):
        return f(a)
      case let .Throw(error):
        return TypedOperation<B>(queue: self.queue, error: error)
      }
    }
  }

  func transform<B>(f: Try<A> -> TypedOperation<B>) -> TypedOperation<B> {
    // create operation, make it dependent on self, add it to queue
    let toB = TypedOperation<B>(queue: queue) { f(self.result!) }
    toB.addDependency(self)
    queue.addOperation(toB)
    return toB
  }
  // TODO(mgadda): implement SequenceType

}
enum TypedOperationError: ErrorType {
  case UnknownError
}

