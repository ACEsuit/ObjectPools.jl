
using ObjectPools, BenchmarkTools, Test


function chebbasis!(T, x) 
   N = length(T) 
   if N > 0 
      T[1] = one(x) 
   end
   if N > 1 
      T[2] = x 
   end
   for n = 3:N 
      T[n] = 2x*T[n-1] - T[n-2] 
   end
   return T
end

function chebbasis(pool::ArrayPool, x, N) 
   T = acquire!(pool, :T, (N,), typeof(x))
   chebbasis!(T, x) 
   return T
end

function chebbasis(temp::Union{TempArray, FlexTempArray, ArrayCache, FlexArrayCache}, x, N) 
   T = acquire!(temp, (N,), typeof(x))
   chebbasis!(T, x) 
   return T
end

function chebbasis(x, N) 
   T = zeros(typeof(x), N)
   chebbasis!(T, x) 
   return T
end


##


for N in [30, 100, 300, 1000]
   @info("N = $N")

   A1 = zeros(N) 
   A2 = TempArray(Float64, 1)
   A3 = FlexTempArray()
   A4 = ArrayPool(FlexTempArray)
   A5 = ArrayCache(Float64, 1)
   A6 = FlexArrayCache()
      
   x = rand() 

   B0 = chebbasis(x, N)
   B1 = chebbasis!(A1, x)
   B2 = chebbasis(A2, x, N)
   B3 = chebbasis(A3, x, N)
   B4 = chebbasis(A4, x, N)
   B5 = chebbasis(A5, x, N)
   B6 = chebbasis(A5, x, N)

   println(@test B0 == B1 == B2 == B3 == B4 == B5)
end

##


# for N in [30, 100, 300, 1000]
#    @info("N = $N")

#    A1 = zeros(N) 
#    A2 = TempArray(Float64, 1)
#    A3 = FlexTempArray()
#    A4 = ArrayPool(FlexTempArray)
#    A5 = ArrayCache(Float64, 1)
#    A6 = FlexArrayCache()
      
#    x = rand() 

#    print("    allocating: "); @btime chebbasis($x, $N)
#    print(" Pre-allocated: "); @btime chebbasis!($A1, $x);
#    print("     TempArray: "); @btime chebbasis($A2, $x, $N);
#    print(" FlexTempArray: "); @btime chebbasis($A3, $x, $N);
#    print("     ArrayPool: "); @btime chebbasis($A4, $x, $N);
#    print("    ArrayCache: "); @btime (B = chebbasis($A5, $x, $N); release!(B));
#    print("FlexArrayCache: "); @btime (B = chebbasis($A6, $x, $N); release!(B));
# end
