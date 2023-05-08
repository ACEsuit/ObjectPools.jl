# Example Use Cases

The following examples contain code that are not intended to run, but are only indicative. 

## Flexible Temporary Arrays and Output Arrays

The simplest use-case of `ObjectPools.jl` is to have flexible temporary variables and output arrays that can be reused. For example, suppose we want to evaluate the spherical harmonics. This could be implemented as follows

```julia 
struct Ylms
   L::Int 
   tmpP::FlexArray
   outY::FlexArrayCache
end

Ylms(L::Integer) = Ylms(L, FlexArray(), FlexCacheArray())

function (ylms::Ylms)(r::SVector{3, T}) where {T <: Real}
   L = ylms.L
   P = acquire!(ylms.tmpP, (lenP(L),), T)
   eval_alp!(P, r)   # not shown
   Y = acquire!(ylms.outY, (lenY(L),), Complex{T})
   eval_ylm!(Y, P, r)   # not shown
   return Y 
end

ylms = Ylms(L)

for i = 1:niter
   r = @SVector randn(3)  # generate an input somehow 
   Y = ylms(r)            # evaluate the Ylms 
   # ....                   do something with Y 
   release!(Y)            # return it to the pool
end 
```

The first advantage of the above implementation is that the input type parameter `T` need not be known at any point other than runtime. E.g., we can now use `ForwardDiff` to differentiate the basis and the `FlexArray`s will just become arrays of `Dual` numbers. 

The second advantage is that the output array gets released back to the array cache and is not newly allocated at each step. Of course one could instead pre-allocate and write an in-place version of the evaluation code. But this requires type management *outside* of the Ylms implementation, which can get tedious. The `FlexArrayCache` is a simple mechanism to keep all type management *localized* to the actual implementation.

If we wanted to make the `for i = 1:niter` loop multi-threaded then we could rewrite this code as follows: 
```julia 
struct Ylms
   L::Int 
   tmpP::TSafe{FlexArray}
   outY::TSafe{FlexArrayCache}
end

ylms = Ylms(L)

@threads :static for i = 1:niter
   r = @SVector randn(3)  # generate an input somehow 
   Y = ylms(r)            # evaluate the Ylms 
   # ....                   do something with Y 
   release!(Y)            # return it to the pool
end 
```
We use the static scheduler because `TSafe{FlexArray}` is not safe to use with the dynamic scheduler. 

To use the dynamic scheduler we need to swap it for a `TSafe{FlexArrayCache}`: 
```julia 
struct Ylms
   L::Int 
   tmpP::TSafe{FlexArrayCache}
   outY::TSafe{FlexArrayCache}
end

ylms = Ylms(L)

@threads for i = 1:niter
   r = @SVector randn(3)  # generate an input somehow 
   Y = ylms(r)            # evaluate the Ylms 
   # ....                   do something with Y 
   release!(Y)            # return it to the pool
end 
```


