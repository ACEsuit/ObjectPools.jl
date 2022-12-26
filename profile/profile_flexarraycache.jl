
using ObjectPools, BenchmarkTools, SparseArrays, LinearAlgebra
using ObjectPools: FlexArrayCache, ArrayCache, FlexTempArray


_btime = true 
_benchmark = false 

function runn(N, f, args...)
   for _=1:N
      f(args...)
   end
end

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
flextemp = FlexTempArray()

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
_btime     && @btime runn(1000, $f!, $y, $A, $x)
_benchmark && display(@benchmark f!($y, $A, $x))

@info("typed temp")
_btime     && @btime runn(1000, $f1, $A, $x, $temp)
_benchmark && display(@benchmark f1($A, $x, $temp))

@info("flex temp")
_btime     && @btime runn(1000, $f1, $A, $x, $flextemp)
_benchmark && display(@benchmark f1($A, $x, $flextemp))

@info("typed cache")
_btime     && @btime runn(1000, $f1, $A, $x, $cache)
_benchmark && display(@benchmark f1($A, $x, $cache))

@info("flex cache")
_btime     && @btime runn(1000, $f1, $A, $x, $flexcache)
_benchmark && display(@benchmark f1($A, $x, $flexcache))

@info("allocating")
_btime     && @btime runn(1000, $f2, $A, $x)
_benchmark && display(@benchmark f2($A, $x))

@info("in-place again")
_btime     && @btime runn(1000, $f!, $y, $A, $x)
_benchmark && display(@benchmark f!($y, $A, $x))

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
flextemp = FlexTempArray()
nt_temp = (y = FlexTempArray(), a = FlexTempArray(), c = FlexTempArray())
dict_temp = Dict(:y => FlexTempArray(), :a => FlexTempArray(), :c => FlexTempArray())

function g!(y, x, A, B, C)
   @assert length(y) >= length(A)
   @assert length(A) == length(B) == length(C)
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

g1(x, A, B, C, multicache::Union{NamedTuple, Dict}) = 
   g1(x, A, B, C, multicache[:y])


function g2(x, A, B, C) 
   TY = promote_type(typeof(x), eltype(A))
   y = Vector{TY}(undef, size(A, 1))
   g!(y, x, A, B, C)
   return nothing; 
end


@info("in-place")
_btime     && @btime runn(1000, $g!, $y, $x, $A, $B, $C) 
_benchmark && display(@benchmark g!($y, $x, $A, $B, $C)  )

@info("typed temp")
_btime     && @btime runn(1000, $g1, $x, $A, $B, $C, $temp) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $temp)  )

@info("flex temp")
_btime     && @btime runn(1000, $g1, $x, $A, $B, $C, $flextemp) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $flextemp)  )

@info("typed cache")
_btime     && @btime runn(1000, $g1, $x, $A, $B, $C, $cache) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $cache)  )

@info("flex cache")
_btime     && @btime runn(1000, $g1, $x, $A, $B, $C, $flexcache) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $flexcache)  )

@info("with allocation")
_btime     && @btime runn(1000, $g2, $x, $A, $B, $C) 
_benchmark && display(@benchmark g2($x, $A, $B, $C)  )

@info("in-place again")
_btime     && @btime runn(1000, $g!, $y, $x, $A, $B, $C) 
_benchmark && display(@benchmark g!($y, $x, $A, $B, $C)  )

@info("nt flex temp")
_btime     && @btime runn(1000, $g1, $x, $A, $B, $C, $nt_temp) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $nt_temp)  )

@info("dict flex temp")
_btime     && @btime runn(1000, $g1, $x, $A, $B, $C, $dict_temp) 
_benchmark && display(@benchmark g1($x, $A, $B, $C, $dict_temp)  )
