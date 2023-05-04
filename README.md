# ObjectPools

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ACEsuit.github.io/ObjectPools.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ACEsuit.github.io/ObjectPools.jl/dev/) -->
[![Build Status](https://github.com/ACEsuit/ObjectPools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ACEsuit/ObjectPools.jl/actions/workflows/CI.yml?query=branch%3Amain)

Implementation of flexible and thread-safe temporary arrays and array pools for situations where a little bit of semi-manual memory management improves performance. Used quite heavily throughout the ACE codebase, can lead to performance gains anywhere between 0 and 50%. 

### Temporary Arrays

`ObjectPools.jl` exports `TempArray` and `FlexTempArray`, which - as the name suggests - can be used to store temporary arrays that are *somewhat* thread-safe.  They are constructed as follows: 
```julia
tmp = TempArray(Float64, 1)
tmp = FlexTempArray()
```
These store resizable arrays that can be obtained via 
```julia 
A = acquire!(tmp, (N,), Float64)  # N = length of array
``` 
For `TempArray` the `Float64` argument must match the type given in the constructor and the number of dimensions must match the `1` in the constructor, while for `FlexTempArray` this is completely flexible (hence the name). For example, 
```julia
A = acquire!(tmp, (10, 10, 10), Bool)
```
is also allowed. 

In both cases, the object `tmp` actually stores a separate temporary array for each thread. This is *NOT* entirely thread-safe however due to Julia's dynamic scheduler. These arrays are only thread safe when using the static scheduler, e.g. 
```julia 
@threads :static for i = 1:10
   # ... 
end
```

### Array Caches 

`ObjectPools.jl` exports `ArrayCache` and `FlexArrayCache`, which provide thread-safe stacks of arrays to reuse without garbage collection. This can be thought of as a very limited and manual re-implementation of garbage collection. They are used as follows: 
```julia
cache = ArrayCache(Float64, 1)
cache = FlexArrayCache()
A = acquire!(cache, (N, ), Float64)
# do something with A 
release!(A)
```
The `acquire!` function obtains an array of size `(N,)` from the stack (in the current thread). After the array is no longer needed, it can be returned to the stack via `release!`. It is ok if it is never released. Once there is no longer a reference to `A`, it will just be garbage collected. Note that it is possible that an array `A` is aquired in thread i and released in thread j in which case it is released back to a different stack. 

### Array Pools 

A pool is a dictionary of temporary arrays or array caches indexed by symbols. It enables the management of many temporary arrays (or caches) within a single field. For example, 
```julia 
pool = ArrayPool(FlexTempArray)
A = acquire(pool, :A, (10, 10), Float64) 
B = acquire(pool, :B, (10, 100), ComplexF64)
```
