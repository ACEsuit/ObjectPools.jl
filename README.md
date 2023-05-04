# ObjectPools

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ACEsuit.github.io/ObjectPools.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ACEsuit.github.io/ObjectPools.jl/dev/) -->
[![Build Status](https://github.com/ACEsuit/ObjectPools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ACEsuit/ObjectPools.jl/actions/workflows/CI.yml?query=branch%3Amain)

Implementation of flexible and thread-safe temporary arrays and array pools for situations where a little bit of semi-manual memory management improves performance. Used quite heavily throughout the ACE codebase, can lead to performance gains anywhere between 0 and 50%. 

The following Table shows a basic benchmark for evaluating a Chebyshev basis, for multiple inputs at the same time. This is a typical use-case for which this package is intended: the cost of arithmetic is on the same order of magnitude as the cost of allocation. 

<!-- Runtimes of Chebyshev Basis Evaluation in Batches -->
**Format : min-time / mean-time in ns**
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
      <td style = "text-align: right;">147 / 262</td>
      <td style = "text-align: right;">164 / 548</td>
      <td style = "text-align: right;">376 / 827</td>
      <td style = "text-align: right;">414 / 1167</td>
    </tr>
    <tr>
      <td style = "text-align: right;">pre-allocated</td>
      <td style = "text-align: right;">79 / 83</td>
      <td style = "text-align: right;">67 / 67</td>
      <td style = "text-align: right;">261 / 269</td>
      <td style = "text-align: right;">230 / 237</td>
    </tr>
    <tr>
      <td style = "text-align: right;">TempArray</td>
      <td style = "text-align: right;">75 / 77</td>
      <td style = "text-align: right;">67 / 67</td>
      <td style = "text-align: right;">259 / 270</td>
      <td style = "text-align: right;">230 / 238</td>
    </tr>
    <tr>
      <td style = "text-align: right;">FlexTempArray</td>
      <td style = "text-align: right;">90 / 93</td>
      <td style = "text-align: right;">66 / 67</td>
      <td style = "text-align: right;">267 / 274</td>
      <td style = "text-align: right;">261 / 273</td>
    </tr>
    <tr>
      <td style = "text-align: right;">ArrayPool(FlexTemp)</td>
      <td style = "text-align: right;">92 / 94</td>
      <td style = "text-align: right;">69 / 70</td>
      <td style = "text-align: right;">265 / 273</td>
      <td style = "text-align: right;">262 / 274</td>
    </tr>
    <tr>
      <td style = "text-align: right;">ArrayCache</td>
      <td style = "text-align: right;">130 / 256</td>
      <td style = "text-align: right;">153 / 531</td>
      <td style = "text-align: right;">344 / 754</td>
      <td style = "text-align: right;">343 / 1159</td>
    </tr>
    <tr>
      <td style = "text-align: right;">FlexArrayCache</td>
      <td style = "text-align: right;">136 / 257</td>
      <td style = "text-align: right;">162 / 523</td>
      <td style = "text-align: right;">343 / 770</td>
      <td style = "text-align: right;">344 / 1254</td>
    </tr>
    <tr>
      <td style = "text-align: right;">ArrayPool(FlexCache)</td>
      <td style = "text-align: right;">139 / 268</td>
      <td style = "text-align: right;">175 / 544</td>
      <td style = "text-align: right;">346 / 772</td>
      <td style = "text-align: right;">358 / 1200</td>
    </tr>
  </tbody>
</table>

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
