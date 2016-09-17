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
open class AsyncOperationAdapter<A>: TypedOperation<A> {
  public init(f: @escaping (@escaping (A?, Error?) -> ()) throws -> ()) {
    super.init { () -> Try<A> in
      let sema = DispatchSemaphore(value: 0)
      var callbackResult: Try<A>?
      do {
        // f is the computation with a callback
        // it is asynchronous and will return immediately
        try f { (result, error) in
          if let err = error {
            callbackResult = .throw(err)
          } else if let res = result {
            callbackResult = .return(res)
          } else {
            callbackResult = .throw(TypedOperationError.unknownError)
          }
          sema.signal()
        }
      } catch {
        callbackResult = .throw(error)
      }

      let _ = sema.wait(timeout: DispatchTime.distantFuture)
      return callbackResult!
    }
  }
}
