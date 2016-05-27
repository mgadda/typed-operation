import Foundation

let a = TypedOperation(constant: 10)
let b = a.map2 { result in
  result * 10
}
//print(try b.awaitResult())

//let queue = NSOperationQueue()
//let become = TypedOperation(queue: queue, block: { () -> TypedOperation<Int> in
//  let op = TypedOperation(f: { () -> Int in
//    sleep(4)
//    return 10
//  })
//  return op
//})
//queue.addOperation(become)
//
//print(try become.awaitResult())
