

struct FlexArrayCache
   vecs::Stack{Vector{UInt8}}
end

# ----------------------------------- 
# FlexCachedArray implementation 
struct FlexCachedArray{T, N, V1, V2, V3, V4} <: AbstractArray{T, N}
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

# ----------------------------------------------------------------
# We can define an `unwrap` function that will convert the 
# FlexCachedArray into a PtrArray which circumvents a lot of 
# performance problems. 
# This should really be considered a workaround though. A better 
# approach would be to make FlexCachedArray performant. It is just 
# not clear how hard that would be.

# Fallback
unwrap(x::AbstractArray) = x

# this one is the primary use-case
unwrap(x::FlexCachedArray) = x.A

# a few other cases where we can improve on the fall-bask 
unwrap(adj::Adjoint{TT, <: FlexCachedArray} ) where {TT} = unwrap(parent(adj))'
unwrap(adj::Transpose{TT, <: FlexCachedArray} ) where {TT} = unwrap(parent(adj))'
unwrap(adj::Adjoint{TT, <: PtrArray} ) where {TT} = parent(adj)'
unwrap(adj::Transpose{TT, <: PtrArray} ) where {TT} = parent(adj)'

# for some reason @deprecate doesn't work here. Getting 
# error messages we don't understand. This here will do until 
# we tag the next version. 
# In Julia 1.10-beta1 it seems that `parent` is used in ways we didn't 
# expect, causing warnings all over the place, hence we keep this only for 
# older versions of Julia. 
if VERSION < v"1.10-"
   function Base.parent(pA::FlexCachedArray)
      @warn("Use of `parent` to obtain the PtrArray of a FlexCachedArray is deprecated. Use `unwrap` instead.")
      return unwrap(pA)
   end
end 

# ----------------------------------- 
# FlexArrayCache implementation

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
