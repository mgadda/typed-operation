//
//  GRPCOperation.swift
//  bestie
//
//  Created by Matt Gadda on 5/23/16.
//  Copyright © 2016 Matt Gadda. All rights reserved.
//

import Foundation

/// An adapter which makes it possible to wrap external asynchronous 
/// computations, such as those performed by NSURLSession, with TypedOperations.
public class AsyncOperationAdapter<A>: TypedOperation<A> {
  public init(f: ((A?, ErrorType?) -> ()) throws -> ()) {
    super.init { () -> Try<A> in
      let sema = dispatch_semaphore_create(0)
      var callbackResult: Try<A>?
      do {
        // f is the computation with a callback
        // it is asynchronous and will return immediately
        try f { (result, error) in
          if let err = error {
            callbackResult = .Throw(err)
          } else if let res = result {
            callbackResult = .Return(res)
          } else {
            callbackResult = .Throw(TypedOperationError.UnknownError)
          }
          dispatch_semaphore_signal(sema)
        }
      } catch {
        callbackResult = .Throw(error)
      }

      // TODO: do we really want to wait forever?
      dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
      return callbackResult!
    }
  }
}
