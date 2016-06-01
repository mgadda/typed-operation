## Overview

TypedOperation provides (mostly) type-safe chainable, nestable composition of NSOperations. 

[![Build Status](https://travis-ci.org/mgadda/typed-operation.svg?branch=master)](https://travis-ci.org/mgadda/typed-operation)

## Examples

### Chaining

```swift
func doComputation() -> Int 

let result: TypedOperation<Int> = TypedOperation {
  doComputation()
}

result.map { someValue in 
  someValue * 10
}

try result.awaitResult() // 100
```

### Nesting

```swift
TypedOperation<Int>(constant: 10).flatMap { someInt in
  TypedOperation(constant: someInt * 2)
}.awaitResult() // -> 20 :: Int
```

### Error Handling

```swift
enum Error: ErrorType {
  case SomeError
}

let handled = TypedOperation<Int>(error: Error.SomeError).handle { error in
  return 10
}
handled.awaitResult() // => 10

```

Recover using another `TypedOperation`:

```swift

let rescued = TypedOperation<Int>(error: Error.SomeError).rescue { error in
  return TypedOperation<Int>(constant: 10)
}

rescued.awaitResult() // => 10
```

### For side-effects

```swift
TypedOperation(constant: 10).onSuccess { result in 
  print("Result was \(result)")
}.onFailure { error in
  print("Error was \(error)")
}
```

### Joining concurrent operations

```swift
let joinedOperation = TypedOperation(constant: 10).join(TypedOperation(constant: 20))
try joinedOperation.awaitResult() // => Tuple2(10, 20)
```

## Installation

TypedOperation is available as a cocoapod, swift package, or as a standalone framework.

### Cocoapod

### Swift Package

### Framework
