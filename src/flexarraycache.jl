

struct FlexArrayCache
   vecs::Stack{Vector{UInt8}}
end

struct FlexCachedArray{T, N, V1, V2, V3, V4}
   A::PtrArray{T, N, V1, V2, V3, V4}
   _A::Vector{UInt8}
   pool::FlexArrayCache
end


release!(pA::FlexCachedArray) = release!(pA.pool, pA)

using Base: @propagate_inbounds

@propagate_inbounds function Base.getindex(pA::FlexCachedArray, I...) 
   @boundscheck checkbounds(pA.A, I...)
   @inbounds pA.A[I...]
end

@propagate_inbounds function Base.setindex!(pA::FlexCachedArray, val, I...)
   @boundscheck checkbounds(pA.A, I...)
   @inbounds pA.A[I...] = val
end

Base.length(pA::FlexCachedArray) = length(pA.A)

Base.eltype(pA::FlexCachedArray) = eltype(pA.A)

Base.size(pA::FlexCachedArray, args...) = size(pA.A, args...)

Base.parent(pA::FlexCachedArray) = pA.A


FlexArrayCache() = FlexArrayCache(Stack{Vector{UInt8}}())

acquire!(c::FlexArrayCache, len::Integer, args...) = 
      acquire!(c, (len,), args...)


function acquire!(c::FlexArrayCache, sz::NTuple{N, <:Integer}, ::Type{T}
                 ) where {N, T} 
   szofT = sizeof(T)
   szofA = prod(sz) * szofT
   stack = c.vecs
   if isempty(stack)
      _A = Vector{UInt8}(undef, szofA)
   else 
      _A = pop!(stack)
      resize!(_A, szofA)
   end

   return FlexCachedArray(_convert(_A, sz, T), _A, c)
end

release!(c::FlexArrayCache, cA::FlexCachedArray) = 
      push!(c.vecs, cA._A)
