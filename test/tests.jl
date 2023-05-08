
using ObjectPools, BenchmarkTools, Test
using ObjectPools.Testing: chebbasis
##


for N in [30, 100, 300, 1000]
   @info("N = $N")

   A0 = nothing 
   A1 = zeros(N) 
   A2 = FlexArray()
   A3 = ArrayPool(FlexArray)
   A4 = FlexArrayCache()
   A5 = ArrayPool(FlexArrayCache)

   x = rand() 

   B0 = chebbasis(A0, x, N)
   B1 = chebbasis(A1, x, N)
   B2 = chebbasis(A2, x, N)
   B3 = chebbasis(A3, x, N)
   B4 = chebbasis(A4, x, N)
   B5 = chebbasis(A5, x, N)

   println(@test B0 == B1 == B2 == B3 == parent(B4) == parent(B5)) 
end

##
