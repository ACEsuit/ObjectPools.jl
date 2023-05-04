module ObjectPools

function acquire! end 
function release! end 

using Base.Threads: threadid, nthreads
using DataStructures: Stack 
using StrideArrays: PtrArray

export acquire!, 
       release!, 
       ArrayCache, 
       FlexArrayCache, 
       TempArray, 
       FlexTempArray, 
       ArrayPool


function _convert(A::Vector{UInt8}, sz::NTuple{N, <: Integer}, ::Type{T}
                  ) where {T, N}
   Aptr = PtrArray(A)
   Aptr_T = reinterpret(T, Aptr)
   Aptr_T_sz = reshape(Aptr_T, sz)
   return Aptr_T_sz
end

# old version with UnsafeArrays
# ptr = Base.unsafe_convert(Ptr{T}, A)
# return UnsafeArray(ptr, sz)
# return FlexTemp(UnsafeArray(ptr, sz), A) 


include("arraycache.jl")     

include("temparray.jl")

include("flexarraycache.jl")

include("flextemparray.jl")


include("arraypool.jl")

end
