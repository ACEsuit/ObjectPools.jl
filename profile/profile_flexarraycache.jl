
using ObjectPools, BenchmarkTools, SparseArrays, LinearAlgebra
using ObjectPools: FlexArrayCache


## 

@info("Benchmark a mid-scale linear layer")

x = randn(10_000)
A = sprand(1_000, 10_000, 0.002)
y = zeros(1_000)

cache = FlexArrayCache()

function f!(y::Vector, A, x)
   mul!(y, A, x)
end

function f(A, x, cache)
   TY = promote_type(eltype(A), eltype(x))
   y = acquire!(cache, TY, size(A, 1))
   mul!(parent(y), A, x) 
   release!(y)
end

@info("in-place")
display(@benchmark f!($y, $A, $x))

@info("cache")
display(@benchmark f($A, $x, $cache))

##

@info("A small scale polynomial basis")

N = 30 
A = randn(N)
B = randn(N)
C = randn(N)
y = zeros(N)
x = randn() 
cache1 = FlexArrayCache()

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
   y = acquire!(cache, TY, size(A, 1))
   g!(parent(y), x, A, B, C)
   release!(y)
   return nothing; 
end

function g2(x, A, B, C, cache) 
   TY = promote_type(typeof(x), eltype(A))
   y = Vector{TY}(undef, size(A, 1))
   g!(y, x, A, B, C)
   return nothing; 
end


@info("in-place")
display(@benchmark g!($y, $x, $A, $B, $C)  )
@info("with cache")
display(@benchmark g1($x, $A, $B, $C, $cache1)  )
@info("with allocation")
display(@benchmark g2($x, $A, $B, $C, $cache1)  )

