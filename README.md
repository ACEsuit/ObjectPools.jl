# ObjectPools

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ACEsuit.github.io/ObjectPools.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ACEsuit.github.io/ObjectPools.jl/dev/) -->
[![Build Status](https://github.com/ACEsuit/ObjectPools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ACEsuit/ObjectPools.jl/actions/workflows/CI.yml?query=branch%3Amain)

Implementation of flexible (and thread-safe) temporary arrays and array pools for situations where a little bit of semi-manual memory management improves performance. Used quite heavily throughout the ACE codebase, can lead to significant performance gains in some cases. Unfortunately, at this point, those gains are not always as systematic as one would hope. 

The following Table shows a basic benchmark for evaluating a Chebyshev basis, for multiple inputs at the same time. This is a typical use-case for which this package is intended: the cost of arithmetic is on the same order of magnitude as the cost of allocation. 

<!-- Runtimes of Chebyshev Basis Evaluation in Batches -->
<table>
  <thead>
    <tr class = "header headerLastRow">
      <th style = "text-align: right;">nB / nX</th>
      <th style = "text-align: right;">10 / 16</th>
      <th style = "text-align: right;">10 / 32</th>
      <th style = "text-align: right;">30 / 16</th>
      <th style = "text-align: right;">30 / 32</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style = "text-align: right;">Array</td>
      <td style = "text-align: right;">147 / 259</td>
      <td style = "text-align: right;">163 / 566</td>
      <td style = "text-align: right;">377 / 876</td>
      <td style = "text-align: right;">412 / 1286</td>
    </tr>
    <tr>
      <td style = "text-align: right;">pre-allocated</td>
      <td style = "text-align: right;">89 / 97</td>
      <td style = "text-align: right;">65 / 66</td>
      <td style = "text-align: right;">253 / 263</td>
      <td style = "text-align: right;">213 / 214</td>
    </tr>
    <tr>
      <td style = "text-align: right;">FlexArray</td>
      <td style = "text-align: right;">95 / 100</td>
      <td style = "text-align: right;">63 / 63</td>
      <td style = "text-align: right;">264 / 273</td>
      <td style = "text-align: right;">207 / 213</td>
    </tr>
    <tr>
      <td style = "text-align: right;">ArrayPool(FlexArray)</td>
      <td style = "text-align: right;">91 / 93</td>
      <td style = "text-align: right;">68 / 70</td>
      <td style = "text-align: right;">264 / 271</td>
      <td style = "text-align: right;">216 / 223</td>
    </tr>
    <tr>
      <td style = "text-align: right;">FlexArrayCache</td>
      <td style = "text-align: right;">104 / 106</td>
      <td style = "text-align: right;">88 / 94</td>
      <td style = "text-align: right;">280 / 287</td>
      <td style = "text-align: right;">270 / 283</td>
    </tr>
    <tr>
      <td style = "text-align: right;">ArrayPool(FlexArrayCache)</td>
      <td style = "text-align: right;">111 / 112</td>
      <td style = "text-align: right;">93 / 98</td>
      <td style = "text-align: right;">285 / 292</td>
      <td style = "text-align: right;">275 / 287</td>
    </tr>
    <tr>
      <td style = "text-align: right;">TSafe(FlexArray)</td>
      <td style = "text-align: right;">87 / 89</td>
      <td style = "text-align: right;">67 / 68</td>
      <td style = "text-align: right;">262 / 269</td>
      <td style = "text-align: right;">212 / 219</td>
    </tr>
    <tr>
      <td style = "text-align: right;">TSafe(ArrayPool(FlexArray))</td>
      <td style = "text-align: right;">96 / 97</td>
      <td style = "text-align: right;">74 / 77</td>
      <td style = "text-align: right;">262 / 271</td>
      <td style = "text-align: right;">224 / 232</td>
    </tr>
  </tbody>
</table>

### `FlexArray`

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

### `FlexArrayCache`

`ObjectPools.jl` exports `FlexArrayCache`, which provides stacks of arrays to reuse without garbage collection. This can be thought of as a very limited and manual re-implementation of garbage collection. They are used as follows: 
```julia
cache = FlexArrayCache()
A = acquire!(cache, (N, ), Float64)
# do something with A 
release!(A)
```
The `acquire!` function obtains an array of size `(N,)` from the stack (in the current thread). After the array is no longer needed, it can be returned to the stack via `release!`. It is ok if it is never released. Once there is no longer a reference to `A`, it will just be garbage collected. 

### Array Pools 

A pool is a dictionary of temporary arrays or array caches indexed by symbols. It enables the management of many temporary arrays (or caches) within a single field. For example, 
```julia 
pool = ArrayPool(FlexArray)
A = acquire!(pool, :A, (10, 10), Float64) 
B = acquire!(pool, :B, (10, 100), ComplexF64)
```
One can similarly create a `ArrayPool(FlexArrayCache)`

### Thread Safety 

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


