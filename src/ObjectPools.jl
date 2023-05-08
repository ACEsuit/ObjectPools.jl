module ObjectPools

function acquire! end 
function release! end 

using Base.Threads: threadid, nthreads
using DataStructures: Stack 
using StrideArrays: PtrArray

export acquire!, 
       release!, 
       FlexArray,
       ArrayPool,
       FlexArrayCache, 
       ThreadSafe
       # ArrayCache, 
       # TempArray, 


function _convert(A::Vector{UInt8}, sz::NTuple{N, <: Integer}, ::Type{T}
                  ) where {T, N}
   Aptr = PtrArray(A)
   Aptr_T = reinterpret(T, Aptr)
   Aptr_T_sz = reshape(Aptr_T, sz)
   return Aptr_T_sz
end

release!(::Any) = nothing 

include("threadsafe.jl")
include("flexarray.jl")
include("flexarraycache.jl")
include("arraypool.jl")

# include("arraycache.jl")     
# include("temparray.jl")

end
