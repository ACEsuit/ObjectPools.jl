using UnsafeArrays

struct FlexArrayCache
   vecs::Vector{Stack{Vector{UInt8}}}
end


struct FlexCachedArray{T, N} <: AbstractArray{T, N}
   A::UnsafeArray{T, N}
   _A::Vector{UInt8}
   pool::FlexArrayCache
end


# release!(A::Any) = nothing 
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

# Base.getindex(pA::CachedArray, args...) = getindex(pA.A, args...)

# Base.setindex!(pA::CachedArray, args...) = setindex!(pA.A, args...)

Base.length(pA::FlexCachedArray) = length(pA.A)

Base.eltype(pA::FlexCachedArray) = eltype(pA.A)

Base.size(pA::FlexCachedArray, args...) = size(pA.A, args...)

Base.parent(pA::FlexCachedArray) = pA.A


function FlexArrayCache() 
   nt = nthreads()
   vecs = [ Stack{Vector{UInt8}}() for _=1:nt ]
   return FlexArrayCache(vecs)
end


function acquire!(c::FlexArrayCache, len::Integer, ::Type{T}) where {T} 
   szofT = sizeof(T)
   szofA = len * szofT
   stack = c.vecs[threadid()]
   if isempty(stack)
      _A = Vector{UInt8}(undef, szofA)
   else 
      _A = pop!(stack)
      resize!(_A, szofA)
   end
   # A = reinterpret(T, _A)
   # return FlexCachedArray(A, c)

   ptr = Base.unsafe_convert(Ptr{T}, _A)
   # A = Base.unsafe_wrap(Array, ptr, len)
   A = UnsafeArray(ptr, (len,))
   return FlexCachedArray(A, _A, c)
end

# release!(c::FlexArrayCache, cA::FlexCachedArray) = 
#       push!(c.vecs[threadid()], parent(cA.A))

release!(c::FlexArrayCache, cA::FlexCachedArray) = 
      push!(c.vecs[threadid()], cA._A)
