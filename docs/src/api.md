
# API

## `FlexArray`

`ObjectPools.jl` exports `FlexArray` which can be used to keep memory for an array and adapt its type and size as needed. In particular the eltype and size can change at runtime without performance loss. They are constructed as follows: 
```julia
tmp = FlexArray()
```
This stores a resizable array that can be obtained via 
```julia 
A = acquire!(tmp, (N,), Float64)  # N = length of array
A = acquire!(tmp, (10, 10, 10), Bool)
``` 
The object `tmp` actually stores a `Vector{UInt8}` which is converted into a `PtrArray` and then re-interpreted and reshaped at essentially zero-cost.

## `FlexArrayCache`

`ObjectPools.jl` exports `FlexArrayCache`, which provides stacks of arrays to reuse without garbage collection. This can be thought of as a very limited and manual re-implementation of garbage collection. They are used as follows: 
```julia
cache = FlexArrayCache()
A = acquire!(cache, (N, ), Float64)
# do something with A 
release!(A)
```
The `acquire!` function obtains an array of size `(N,)` from the stack (in the current thread). After the array is no longer needed, it can be returned to the stack via `release!`. It is ok if it is never released. Once there is no longer a reference to `A`, it will just be garbage collected. 

## Array Pools 

A pool is a dictionary of temporary arrays or array caches indexed by symbols. It enables the management of many temporary arrays (or caches) within a single field. For example, 
```julia 
pool = ArrayPool(FlexArray)
A = acquire!(pool, :A, (10, 10), Float64) 
B = acquire!(pool, :B, (10, 100), ComplexF64)
```
One can similarly create a `ArrayPool(FlexArrayCache)`

## Thread Safety 

In multi-threaded code it can become important that each thread uses its own temporary work array. This can be achieved by wrapping a `FlexArray` or `FlexArrayCache` or an `ArrayPool` into a `TSafe`, e.g. 
```julia 
tmp = TSafe(ArrayPool(FlexArrayCache))
```
We can now access this as follows: 
```julia
@threads for n = 1:N 
   A = acquire!(tmp, :A, (10,10), SVector{3, Float64}) 
   # do something with A 
   release!(A)
end 
```
Here, `tmp` actually stores a separate `ArrayPool` for each thread. Note that due to the dynamic scheduler it is possible that an array `A` is aquired in thread `i` and released in thread `j` in which case it is released back to a different stack. 

Note that due to the dynamics scheduler, `TSafe(FlexArray)` is *NOT* entirely thread-safe. These arrays are only thread safe when using the static scheduler, e.g. 
```julia 
tmp = TSafe(FlexCache)
@threads :static for i = 1:10
   A = acquire!(tmp, (20, 30, 5), ComplexF32) 
   # do something with A 
end
```


