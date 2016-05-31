import Foundation

// ------------------------
// Test flatmap

let b2 = TypedOperation(constant: 10).flatMap { (result) -> TypedOperation<Int> in
  TypedOperation {
    // Increases liklihood of race condition, if present
    //sleep(2)
    return result * 10
  }
}
print(try b2.awaitResult())

// ------------------------
// Test map

let b = TypedOperation(constant: 10).map { result -> Int in
  // Increases liklihood of race condition, if present
  //sleep(2)
  return result * 10
}
print(try b.awaitResult())

// ------------------------
// Test throwing operations

class TestError : ErrorType {}
let op = TypedOperation<Int>() {
  throw TestError()
}

let op2 = op.map { result -> Int in
  //sleep(2)
  return result * 10
}

let result = try? op2.awaitResult()