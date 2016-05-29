import Foundation

let a = TypedOperation(constant: 10)

let b2 = a.flatMap2 { (result) -> TypedOperation<Int> in
  TypedOperation {
    sleep(2)
    return result * 10
  }
}
print(try b2.awaitResult())


let b = TypedOperation(constant: 10).map2 { result in
  result * 10
}
print(try b.awaitResult())


let queue = NSOperationQueue()
let become = TypedOperation(queue: queue) { () -> TypedOperation<Int> in
  let op = TypedOperation<Int>() {
    sleep(4)
    return 10
  }
  return op
}

queue.addOperation(become)

print(try become.awaitResult())
