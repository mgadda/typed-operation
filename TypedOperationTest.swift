
// Testing transform
let transformOp = TypedOperation(constant: 10)
let transformed = transformOp.transform { (result) -> TypedOperation<Float> in
  do {
    let someInt = try result.get()
    return TypedOperation<Float>(constant: Float(someInt) * 3.141)
  } catch {
    return TypedOperation<Float>(queue: transformOp.queue, error: TypedOperationError.UnknownError)
  }

}

try transformed.awaitResult()

// Testing flatMap2
let flatMapOp = TypedOperation(constant: 10)
let flatMapped = flatMapOp.flatMap2 { (someInt) -> TypedOperation<Int> in
  return TypedOperation<Int>(constant: someInt * 3)
}

try flatMapped.awaitResult()

// Testing map
let mapOp = TypedOperation(constant: 10)
let mapped = mapOp.map2 { (someInt) in
  someInt * 45
}

try mapped.awaitResult()

// Testing flatMap, map
let op = TypedOperation(constant: 10).flatMap2 { i in
  return TypedOperation(constant: 20).map2 { j in
    i * j
  }
}
//try op.awaitResult()
