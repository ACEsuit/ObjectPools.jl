using Base.Threads: threadid, nthreads
using DataStructures: Stack 

export ArrayCache

struct ArrayCache{T, N}
   cache::Vector{Stack{Array{T, N}}}
end

struct CachedArray{T, N} <: AbstractArray{T, N} 
   A::Array{T, N}
   pool::ArrayCache{T, N}
end

release!(A::Any) = nothing 

# here we are assuming that that array doesn't get passed around different 
# threads but will be released in the same thread it was acquired in.
# if this fails, the code remains *correct* but might become inefficient.
release!(pA::CachedArray) = release!(pA.pool, pA)

using Base: @propagate_inbounds

@propagate_inbounds function Base.getindex(pA::CachedArray, I...) 
   @boundscheck checkbounds(pA.A, I...)
   @inbounds pA.A[I...]
end

@propagate_inbounds function Base.setindex!(pA::CachedArray, val, I...)
   @boundscheck checkbounds(pA.A, I...)
   @inbounds pA.A[I...] = val
end

Base.length(pA::CachedArray) = length(pA.A)

Base.eltype(pA::CachedArray) = eltype(pA.A)

Base.size(pA::CachedArray, args...) = size(pA.A, args...)

Base.parent(pA::CachedArray) = pA.A

ArrayCache(T, N) = ArrayCache{T, N}() 

function ArrayCache{T, N}() where {T, N}
   nt = nthreads() 
   cache = [ Stack{Array{T, N}}() for _ = 1:nt ] 
   return ArrayCache{T, N}(cache)
end


acquire!(c::ArrayCache, len::Integer, args...) = 
         acquire!(c, (len,), args...)

acquire!(c::ArrayCache{T, N}, sz::NTuple{N, <: Integer}, ::Type{S}) where {N, T, S} =
         Array{S, N}(undef, sz)

acquire!(c::ArrayCache{T, N}, sz::NTuple{N, <: Integer}, ::Type{T}) where {T, N} = 
         acquire!(c, sz)

function acquire!(c::ArrayCache{T, N}, sz::NTuple{N, <: Integer}) where {T, N}
   stack = c.cache[threadid()]
   if isempty(stack)
      A = Array{T, N}(undef, sz)
   else 
      A = pop!(stack)
      if !all(sz .<= size(A))
         A = Array{T, N}(undef, sz)
      end
   end
   return CachedArray(A, c)
end

release!(c::ArrayCache{T, N}, cA::CachedArray{T, N})  where {T, N} = 
      push!(c.cache[threadid()], cA.A)

