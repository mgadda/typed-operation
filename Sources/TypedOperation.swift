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
public class TypedOperation<A: Equatable>: NSOperation {
  var result: Try<A>? = nil

  let computation: () -> Try<A>
  var queue: NSOperationQueue

  static func makeQueue() -> NSOperationQueue {
    let q = NSOperationQueue()
    //q.maxConcurrentOperationCount = 1
    q.name = "TypedOperation<\(A.self)> " + unsafeAddressOf(self).debugDescription
    return q
  }

  private static var defaultQueue: NSOperationQueue {
    return makeQueue()
  }

  // A typed operation that resolves to `constant`
//  init(constant: A) {
//    self.queue = TypedOperation.defaultQueue
//    computation = {
//      return .Return(constant)
//    }
//    super.init()
//    self.queue.addOperation(self)
//  }

  /**
   Immediately enqueue the block defined by f for execution.
   */
  init(f: () throws -> A) {
    queue = TypedOperation.makeQueue()//TypedOperation.defaultQueue
    computation = {
      do {
        return .Return(try f())
      } catch {
        return .Throw(error)
      }
    }
    super.init()
    queue.addOperation(self)
  }

  convenience init(constant: A) {
    self.init() { .Return(constant) }
  }

  // Create a TypedOperation that is an immediate failure
  convenience init(error: ErrorType) {
    self.init() { .Throw(error) }
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

  // `f` directly becomes the computation of this `TypedOperation<A>`
  // Operation runs in its own queue and is immediately enqueued.
  private init(tryBlock: () -> Try<A>) {
    queue = TypedOperation.makeQueue()
    computation = tryBlock
    super.init()
    queue.addOperation(self)
  }

  private init(queue: NSOperationQueue, tryBlock: () -> Try<A>) {
    self.queue = queue
    computation = tryBlock

    super.init()
    // Do not enqueue operation, caller will handle this
  }

  // Execute `block` and flatten its result into `self.result`.
  private init(queue: NSOperationQueue, typedOpBlock: () -> TypedOperation<A>) {
    self.queue = queue

    computation = {
      let op = typedOpBlock()
      op.waitUntilFinished()

      return op.result!
    }
    super.init()
  }

  override public func main() {
    result = computation()
  }

  /**
   Waits on the operation until it transitions to the finished
   state. That is, until the finished property is true.
   
   This is probably not the method you're looking for. If you use this method
   in the main thread, your user interface will _stop responding_ until this
   method returns.
   */
  func awaitResult() throws -> A {
    waitUntilFinished()
    return try result!.get() // assumes A always succeeds (not correct)
  }

  /**
   Join the results of the target operation and the argument operation.
   */
  func join<B: Equatable>(operation: TypedOperation<B>) -> TypedOperation<Tuple2<A, B>> {
    // Make new typed operation which is dependent up on these two operations
    let toAB = TypedOperation<Tuple2<A, B>>(queue: queue) {
      self.result!.flatMap({ (aResult) in
        operation.result!.map({ (bResult) in
          Tuple2(aResult, bResult)
        })
      })      
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
      self.result!.handle(f)
    }
    handleOp.addDependency(self)
    queue.addOperation(handleOp)
    return handleOp
  }

  func rescue<B>(f: ErrorType -> TypedOperation<B>) -> TypedOperation<B> {
    return transform { (result) -> TypedOperation<B> in
      switch result {
      case let .Throw(error):
        return f(error)
      case .Return:
        // return self // this would be possible if B >: A
        return TypedOperation<B> {
          result.map { (a) -> B in
            a as! B
          }
        }
      }
    }
  }

  func map<B>(f: A throws -> B) -> TypedOperation<B> {
    return transform({ (result) -> TypedOperation<B> in
      switch result {
      case let .Return(a):
        // This operation _must_ not enqueue in the same queue as self. Otherwise deadlock is all but guaranteed.
        return TypedOperation<B> {
          try f(a)
        }
      case let .Throw(error):                
        return TypedOperation<B>(error: error)
      }
    })
  }

  func flatMap<B>(f: A throws -> TypedOperation<B>) -> TypedOperation<B> {
    return transform { (result) -> TypedOperation<B> in
      switch result {
      case let .Return(a):
        do {
          return try f(a)
        } catch {
          return TypedOperation<B>(error: error)
        }
      case let .Throw(error):
        return TypedOperation<B>(error: error)
      }
    }
  }

  // Invoke `f` with the results of this operation, once they're 
  // available. The `TypedOperation<B>` returned by `f` must be scheduled
  // in distinct queue than self.
  func transform<B>(f: Try<A> -> TypedOperation<B>) -> TypedOperation<B> {
    let toB = TypedOperation<B>(queue: queue) {
      f(self.result!)
    }
    toB.addDependency(self)
    queue.addOperation(toB)
    return toB
  }

  // TODO(mgadda): implement SequenceType
}

public enum TypedOperationError: ErrorType {
  case UnknownError
}

