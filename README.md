![Typed Operation](/typed_operation.png?raw=true "Typed Operation")

## Overview

TypedOperation provides type-safe chainable, nestable composition of NSOperations.

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

## Wrapping NSURLSessionTasks

Many existing libraries offer asynchronous methods which accept callback functions.
Using `AsynchOperationAdapter`, you can wrap those existing asynchonrous operations
to produce `TypedOperations`.

```swift
protocol SomeService {
  func doAsyncThing(callback: (ResultType?, NSError?) -> ())
}

let service: SomeService = /* ... */

AsyncOperationAdapter<ResultType> { service.doAsyncThing(callback: $0) }
```

Or using NSURLSessions:

```swift
let url: NSURL! = NSURL(string: "http://api.example.com")
let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

let op = AsyncOperationAdapter<NSData> { completionHandler in
  let task = session.dataTaskWithURL(url) { (maybeData, maybeResponse, maybeError) in
    completionHandler(maybeData, maybeError)
  }
  task.resume()
}
op.onSuccess { (response: NSData) in
  print(response)
}
```

## Installation

TypedOperation is available as a cocoapod. In your `Podfile`, add:

```ruby
pod 'TypedOperation'
```

Then do the normal thing and run:

```bash
$ pod install
```

If all goes well, open the generated (or updated) xcworkspace and
add the following to any file where you'd like to use a `TypedOperation`:

```swift
import TypedOperation
```
