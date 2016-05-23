import Foundation

// Adds type safety and implicity dependencies between NSOperations
class TypedOperation<A>: NSOperation {
  var result: A? = nil
  let computation: () -> A
  let queue: NSOperationQueue
  
  init(f: () -> A) {
    self.queue = NSOperationQueue()
    computation = f
    super.init()
    self.queue.addOperation(self)
  }
  
  private init(queue: NSOperationQueue, _ f: () -> A) {
    self.queue = queue
    computation = f
    super.init()
    // Do not enqueue operation
  }
  
  override func main() {
    result = computation()
  }
  
  func map<B>(f: (A) -> B) -> TypedOperation<B> {
    let toB = TypedOperation<B>(queue: queue) {
      f(self.result!) // assumes A always succeeds (not correct)
    }
    // PROBLEM: operation may already be executing by the time
    // this dependency is added, which will certainly break a
    // multitude of ways.
    toB.addDependency(self)
    queue.addOperation(toB)
    return toB
  }
 
  // This is not the method you're looking for (probably).
  func awaitResult() -> A {
    waitUntilFinished()
    return result! // assumes A always succeeds (not correct)
  }
}


let op = TypedOperation<Int>() {
  let i = 10
  return i * 20
}

let op2 = op.map { val -> Float in
  let f: Float = Float(val) * 3.14159
  print(f)
  return f
}

op2.awaitResult()


let op3 = TypedOperation<Int>() {
  sleep(2)
  return 10
}.map { (i) -> Float in
  sleep(2)
  return Float(i) * 1.5332
}.map { (f) -> Int in
  Int(f)
}

op3.awaitResult()