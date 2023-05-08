# j18 --project=.. -O3 profile_cheb.jl

using ObjectPools, BenchmarkTools, Test, PrettyTables
using ObjectPools.Testing: chebbasis 


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
   "TSafe(FlexArray)" => TSafe(FlexArray()),
   "TSafe(ArrayPool(FlexArray))" => TSafe(ArrayPool(FlexArray)),
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
         "TSafe(FlexArray)",
         "TSafe(ArrayPool(FlexArray))",
         ]

_make_entry(tt) = "$(round(Int,tt[1])) / $(round(Int, tt[2]))"
_make_row(key) = reshape([ [key]; [_make_entry(tt) for tt in results[key]]], 1, :)

tbl_data = vcat( [_make_row(key) for key in ordered_keys]... )

println("Runtimes of Chebyshev Basis Evaluation in Batches")
println(" Format : min-time / mean-time in µs")

pretty_table(tbl_data; header=header, 
             formatters=ft_printf("%.0f"),
             backend = Val(:html))

pretty_table(tbl_data; header=header, 
             formatters=ft_printf("%.0f"),)


