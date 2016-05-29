import Foundation

let b2 = TypedOperation(constant: 10).flatMap { (result) -> TypedOperation<Int> in
  TypedOperation {
    // Increases liklihood of race condition, if present
    sleep(2)
    return result * 10
  }
}
print(try b2.awaitResult())


let b = TypedOperation(constant: 10).map { result -> Int in
  // Increases liklihood of race condition, if present
  sleep(2)
  return result * 10
}
print(try b.awaitResult())


let queue = NSOperationQueue()
let become = TypedOperation(queue: queue) { () -> TypedOperation<Int> in
  let op = TypedOperation<Int>() {
    // Increases liklihood of race condition, if present
    sleep(2)
    return 10
  }
  return op
}

queue.addOperation(become)

print(try become.awaitResult())
