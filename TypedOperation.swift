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
  
  let computation: () throws -> A
  let queue: NSOperationQueue
  
  // A typed operation that resolves to `constant`
  init(constant: A) {
    self.queue = NSOperationQueue()
    computation = {
      return constant
    }
    super.init()
    self.queue.addOperation(self)
  }
  
  private init(queue: NSOperationQueue, constant: A) {
    self.queue = queue
    computation = {
      return constant
    }
    super.init()
    // Do not enqueue operation, call will handle this
  }
  
  /**
   Immediately enqueue the block defined by f for execution.
   */
  init(f: () throws -> A) {
    self.queue = NSOperationQueue()
    computation = f
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
    computation = f
    super.init()
    // Do not enqueue operation, call will handle this
  }
  
  override func main() {
    do {
      let unwrapped = try computation()
      result = .Return(unwrapped)
    } catch {
      result = .Throw(error)
    }
  }
  
  /**
   If result of target succeeds, f is invoked with result
   If result does not succeed, f is not invoked.
   */
  func map<B>(f: (A) -> B) -> TypedOperation<B> {
    let toB = TypedOperation<B>(queue: queue) {
      // result must have value by the time this operation executes
      // Luckily, this is guaranteed by NSOperation.addDependency.
      let nextResult = self.result!.map { f($0) }
      // This logic is probably not correct
      switch nextResult {
      case let .Return(b):
        return b
      case let .Throw(err):
        throw err
      }
    }
    
    toB.addDependency(self)
    queue.addOperation(toB)
    return toB
  }

  
  func flatMap<B>(f: A -> TypedOperation<B>) -> TypedOperation<B> {
    // Create an operation B which accepts A as an argument
    // the resulting operation should be dependent upon self
    
    // Create an untyped dependent operation which invokes f to produce
    // TypedOperation<B>
    let op = NSBlockOperation {
      self.result!.map { f($0) }
    }
    op.addDependency(self)
    queue.addOperation(op)
    return TypedOperation<B>(operation: op)
  }
  
  private init(operation: NSBlockOperation) {
    super.
    computation = {
      
    }
    addDependency(operation)
    super.init()
    
  }
  
  /**
   Waits on the operation until it transitions to the finished
   state. That is, until the finished property is true.
   This is not the method you're looking for (probably).
   */
  func awaitResult() throws -> A {
    waitUntilFinished()
    return try result!.get() // assumes A always succeeds (not correct)
  }
}