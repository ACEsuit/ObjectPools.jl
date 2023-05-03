using Base.Threads: threadid, nthreads

export FlexTempArray



"""
Thread-safe temporary array for a given type and dimensionality. 
"""
struct FlexTempArray
   t::Vector{Vector{UInt8}}
end

FlexTempArray(; sizehint=0) = 
   FlexTempArray( [ Vector{UInt8}(undef, sizehint) for _ = 1:nthreads() ] )

acquire!(t::FlexTempArray, len::Integer, args...) = 
         acquire!(t, (len,), args...)

function acquire!(c::FlexTempArray, sz::NTuple{N, <: Integer}, ::Type{T}
                  ) where {T, N}
   tid = threadid()
   szofT = sizeof(T)
   szofA = prod(sz) * szofT

   A = c.t[tid]
   len0 = length(A) 
   if !(szofA <= len0)
      A = Vector{UInt8}(undef, szofA) 
      c.t[tid] = A
   end

   Aptr = PtrArray(A) 
   return reshape(reinterpret(T, Aptr), sz)

   # old version with UnsafeArrays
   # ptr = Base.unsafe_convert(Ptr{T}, A)
   # return UnsafeArray(ptr, sz)
   # return FlexTemp(UnsafeArray(ptr, sz), A) 
end
