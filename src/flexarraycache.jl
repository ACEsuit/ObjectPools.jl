

struct FlexArrayCache
   vecs::Vector{Stack{Vector{UInt8}}}
end

struct FlexCachedArray{TA} 
   A::TA
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


function FlexArrayCache() 
   nt = nthreads()
   vecs = [ Stack{Vector{UInt8}}() for _=1:nt ]
   return FlexArrayCache(vecs)
end

acquire!(c::FlexArrayCache, len::Integer, args...) = 
      acquire!(c, (len,), args...)


function acquire!(c::FlexArrayCache, sz::NTuple{N, <:Integer}, ::Type{T}
                 ) where {N, T} 
   szofT = sizeof(T)
   szofA = prod(sz) * szofT
   stack = c.vecs[threadid()]
   if isempty(stack)
      _A = Vector{UInt8}(undef, szofA)
   else 
      _A = pop!(stack)
      resize!(_A, szofA)
   end

   return _convert(_A, sz, T)
end

release!(c::FlexArrayCache, cA::FlexCachedArray) = 
      push!(c.vecs[threadid()], cA._A)
