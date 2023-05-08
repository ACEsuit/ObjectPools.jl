
"""
Array that can be converted into any given eltype and dimensionality. 
"""
mutable struct FlexArray
   A::Vector{UInt8}
end

FlexArray(; sizehint=0) = 
   FlexArray(Vector{UInt8}(undef, sizehint))

acquire!(t::FlexArray, len::Integer, args...) = 
         acquire!(t, (len,), args...)

function acquire!(flex::FlexArray, sz::NTuple{N, <: Integer}, ::Type{T}
                  ) where {T, N}
   szofT = sizeof(T)
   szofA = prod(sz) * szofT
   if !(szofA <= length(flex.A))
      flex.A = Vector{UInt8}(undef, szofA)
   end
   return return _convert(flex.A, sz, T)
end


