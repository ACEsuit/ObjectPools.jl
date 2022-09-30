

struct GenArrayCache
   vecs::Vector{Stack{Vector{UInt8}}}
end

# struct GenCachedArray{T, N, AT <: AbstractArray{T, N}} <: AbstractArray{T, N}
#    A::AT
#    pool::GenArrayCache
# end

using UnsafeArrays

struct GenCachedArray{T, N} <: AbstractArray{T, N}
   A::UnsafeArray{T, N}
   _A::Vector{UInt8}
   pool::GenArrayCache
end


# release!(A::Any) = nothing 
release!(pA::GenCachedArray) = release!(pA.pool, pA)

using Base: @propagate_inbounds

@propagate_inbounds function Base.getindex(pA::GenCachedArray, I...) 
   @boundscheck checkbounds(pA.A, I...)
   @inbounds pA.A[I...]
end

@propagate_inbounds function Base.setindex!(pA::GenCachedArray, val, I...)
   @boundscheck checkbounds(pA.A, I...)
   @inbounds pA.A[I...] = val
end

# Base.getindex(pA::CachedArray, args...) = getindex(pA.A, args...)

# Base.setindex!(pA::CachedArray, args...) = setindex!(pA.A, args...)

Base.length(pA::GenCachedArray) = length(pA.A)

Base.eltype(pA::GenCachedArray) = eltype(pA.A)

Base.size(pA::GenCachedArray, args...) = size(pA.A, args...)

Base.parent(pA::GenCachedArray) = pA.A


function GenArrayCache() where {T} 
   nt = nthreads()
   vecs = [ Stack{Vector{UInt8}}() for _=1:nt ]
   return GenArrayCache(vecs)
end


function acquire!(c::GenArrayCache, ::Type{T}, len::Integer) where {T} 
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
   # return GenCachedArray(A, c)

   ptr = Base.unsafe_convert(Ptr{T}, _A)
   # A = Base.unsafe_wrap(Array, ptr, len)
   A = UnsafeArray(ptr, (len,))
   return GenCachedArray(A, _A, c)
end

# release!(c::GenArrayCache, cA::GenCachedArray) = 
#       push!(c.vecs[threadid()], parent(cA.A))

release!(c::GenArrayCache, cA::GenCachedArray) = 
      push!(c.vecs[threadid()], cA._A)
