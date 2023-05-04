# currenlty not included in the package

using Base.Threads: threadid, nthreads

export FlexTempArray



"""
Thread-safe temporary array for a given type and dimensionality. 
"""
struct FlexTempArray1
   t::Vector{UInt8}
end

FlexTempArray(; sizehint=0) = 
      FlexTempArray(Vector{UInt8}(undef, sizehint))

acquire!(t::FlexTempArray, len::Integer, args...) = 
      acquire!(t, (len,), args...)

function acquire!(c::FlexTempArray, sz::NTuple{N, <: Integer}, ::Type{T}
                  ) where {T, N}
   szofT = sizeof(T)
   szofA = prod(sz) * szofT

   len0 = length(c.t) 
   if !(szofA <= len0)
      resize!(c.t, szofA)
   end

   return _convert(c.t, sz, T)
end
