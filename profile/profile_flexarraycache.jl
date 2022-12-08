
using ObjectPools, BenchmarkTools, SparseArrays, LinearAlgebra
using ObjectPools: FlexArrayCache, ArrayCache


_btime = true 
_benchmark = false 

## 

@info("""======================================
      Benchmark a mid-scale linear layer
============================================""")

x = randn(10_000)
A = sprand(1_000, 10_000, 0.002)
y = zeros(1_000)

flexcache = FlexArrayCache()
cache = ArrayCache{Float64, 1}()
temp = TempArray{Float64, 1}( (size(A, 1),) )

function f!(y::Vector, A, x)
   mul!(y, A, x)
end

function f1(A, x, cache)
   TY = promote_type(eltype(A), eltype(x))
   y = acquire!(cache, size(A, 1), TY)
   mul!(parent(y), A, x) 
   release!(y)
end

function f2(A, x)
   TY = promote_type(eltype(A), eltype(x))
   y = Vector{TY}(undef, size(A, 1))
   mul!(y, A, x)
end

@info("in-place")
_btime     && @btime f!($y, $A, $x)
_benchmark && display(@benchmark f!($y, $A, $x))

@info("typed temp")
_btime     && @btime f1($A, $x, $temp)
_benchmark && display(@benchmark f1($y, $A, $temp))

@info("flex-cache")
_btime     && @btime f1($A, $x, $flexcache)
_benchmark && display(@benchmark f1($A, $x, $flexcache))

@info("typed-cache")
_btime     && @btime f1($A, $x, $cache)
_benchmark && display(@benchmark f1($A, $x, $cache))

@info("allocating")
_btime     && @btime f2($A, $x)
_benchmark && display(@benchmark f2($A, $x))

##

@info("""======================================
    A small scale polynomial basis
============================================""")

N = 30 
A = randn(N)
B = randn(N)
C = randn(N)
y = zeros(N)
x = randn() 
flexcache = FlexArrayCache()
cache = ArrayCache{Float64, 1}()
temp = TempArray{Float64, 1}( (length(A),) )

function g!(y, x, A, B, C)
   y[1] = A[1] 
   y[2] = (A[2] * x + B[2]) * y[2]
   @inbounds for n = 3:size(A, 1)
      y[n] = (A[n] * x + B[n]) * y[n-1] + C[n] * y[n-2] 
   end
   return y 
end

function g1(x, A, B, C, cache) 
   TY = promote_type(typeof(x), eltype(A))
   y = acquire!(cache, size(A, 1), TY)
   g!(parent(y), x, A, B, C)
   release!(y)
   return nothing; 
end

function g2(x, A, B, C) 
   TY = promote_type(typeof(x), eltype(A))
   y = Vector{TY}(undef, size(A, 1))
   g!(y, x, A, B, C)
   return nothing; 
end


@info("in-place")
_btime     && @btime g!($y, $x, $A, $B, $C) 
_benchmark && display(@benchmark g!($y, $x, $A, $B, $C)  )

@info("typed temp")
_btime     && @btime g1($x, $A, $B, $C, $temp) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $temp)  )

@info("flex-cache")
_btime     && @btime g1($x, $A, $B, $C, $flexcache) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $flexcache)  )

@info("typed-cache")
_btime     && @btime g1($x, $A, $B, $C, $cache) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $cache)  )

@info("with allocation")
_btime     && @btime g2($x, $A, $B, $C) 
_benchmark && display(@benchmark g2($x, $A, $B, $C)  )


