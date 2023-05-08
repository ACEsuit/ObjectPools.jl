# j18 --project=.. -O3 profile_cheb.jl

using ObjectPools, BenchmarkTools, Test, PrettyTables

function chebbasis!(T, x::Real) 
   N = length(T) 
   @assert N > 2
   @inbounds begin 
      T[1] = one(x) 
      T[2] = x 
      for n = 3:N 
         T[n] = 2x*T[n-1] - T[n-2] 
      end
   end
   return T
end

function chebbasis!(T, X::AbstractVector{<: Real}) 
   NX = length(X) 
   NT = size(T, 2)
   @assert size(T, 1) >= NX
   @assert NT > 2
   @inbounds begin 
      @simd ivdep for i = 1:NX 
         T[i, 1] = one(eltype(X)) 
         T[i, 2] = X[i]
      end
      for n = 3:NT 
         @simd ivdep for i = 1:NX
            T[i, n] = 2X[i]*T[i, n-1] - T[i, n-2]
         end
      end
   end
   return T
end



function chebbasis(::Nothing, x::Real, N) 
   return chebbasis!(zeros(N), x)
end

function chebbasis(A::Vector, x::Real, N) 
   @assert length(A) == N
   return chebbasis!(A, x)
end

# function chebbasis(pool::ArrayPool, x::Real, N) 
#    T = acquire!(pool, :T, (N,), typeof(x))
#    chebbasis!(parent(T), x) 
#    return T 
# end

# function chebbasis(temp::Union{TempArray, FlexTempArray, ArrayCache, FlexArrayCache}, x::Real, N) 
#    T = acquire!(temp, (N,), typeof(x))
#    chebbasis!(parent(T), x) 
#    return T 
# end

function chebbasis(::Nothing, X::AbstractVector{<: Real}, N) 
   return chebbasis!(zeros(length(X), N), X)
end

function chebbasis(A::Matrix, X::AbstractVector{<: Real}, N) 
   @assert size(A) == (length(X), N)
   return chebbasis!(A, X)
end

function chebbasis(pool::ArrayPool, X::AbstractVector{<: Real}, N) 
   T = acquire!(pool, :T, (length(X), N), eltype(X))
   chebbasis!(parent(T), X) 
   return T 
end

# function chebbasis(temp::Union{TempArray, FlexTempArray, ArrayCache, FlexArrayCache}, X::AbstractVector{<: Real}, N) 
#    T = acquire!(temp, (length(X), N), eltype(X))
#    chebbasis!(parent(T), X) 
#    return T 
# end

function chebbasis(temp::Union{FlexArray, FlexArrayCache}, X::AbstractVector{<: Real}, N) 
   T = acquire!(temp, (length(X), N), eltype(X))
   chebbasis!(parent(T), X) 
   return T 
end

##



NB_ = [10, 30] 
NX_ = [16, 32]
header = [["nB / nX"]; ["$nB / $nX" for nB in NB_ for nX in NX_]]
tests = Dict(
   "Array" => nothing, 
   "pre-allocated" => nothing, 
   "FlexArray" => FlexArray(),
   "FlexArrayCache" => FlexArrayCache(),
   "ArrayPool(FlexArray)" => ArrayPool(FlexArray),
   "ArrayPool(FlexArrayCache)" => ArrayPool(FlexArrayCache),
)
results = Dict()
for key in keys(tests)
   results[key] = Tuple{Float64, Float64}[]
end

for nB in [10, 30], nX in [16, 32]
   X = rand(nX)
   @info("nB = $nB, nX = $nX")
   for (key, A) in tests 
      if key == "pre-allocated"; A = zeros(nX, nB); end 
      # warmup 
      B = chebbasis(A, X, nB); release!(B)
      bm = @benchmark (B = chebbasis($A, $X, $nB); release!(B); )
      t_min = minimum(bm.times)
      t_mean = mean(bm.times)
      @info("$key: $t_min / $t_mean") 
      push!(results[key], (t_min, t_mean))
   end
end

##

ordered_keys = [ 
         "Array",
         "pre-allocated",
         "FlexArray",
         "ArrayPool(FlexArray)",
         "FlexArrayCache",
         "ArrayPool(FlexArrayCache)", 
         ]

_make_entry(tt) = "$(round(Int,tt[1])) / $(round(Int, tt[2]))"
_make_row(key) = reshape([ [key]; [_make_entry(tt) for tt in results[key]]], 1, :)

tbl_data = vcat( [_make_row(key) for key in ordered_keys]... )

println("Runtimes of Chebyshev Basis Evaluation in Batches")
println(" Format : min-time / mean-time in µs")
pretty_table(tbl_data; header=header, 
             formatters=ft_printf("%.0f"),)
            #  backend = Val(:html))

