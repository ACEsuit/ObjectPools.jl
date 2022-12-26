using Base.Threads: threadid, nthreads

export TempArray 

"""
Thread-safe temporary array for a given type and dimensionality. 
"""
struct TempArray{T, N}
   t::Vector{Array{T, N}}
end

TempArray(T, N, sz=ntuple(i->0, N)) = TempArray{T, N}(sz)

TempArray{T, N}(sz::Tuple = ntuple(i->0, N)) where {T, N} = 
   TempArray{T, N}( [ Array{T, N}(undef, sz) for _ = 1:nthreads() ] )

acquire!(t::TempArray{T, 1}, len::Integer, args...) where {T} = 
         acquire!(t, (len,), args...)

acquire!(t::TempArray{T, N}, sz::NTuple{N, Int}, ::Type{S}) where {T, N, S} = 
   Array{S, N}(undef, sz)

acquire!(c::TempArray{T, N}, sz::NTuple{N, Int}, ::Type{T}) where {T, N} = 
   acquire!(c, sz) 

function acquire!(c::TempArray{T, N}, sz::NTuple{N, Int}) where {T, N}   
   tid = threadid()
   A = c.t[tid]
   sz0 = size(A)
   if !all(sz .<= sz0)
      A = Array{T, N}(undef, sz)
      c.t[tid] = A
   end
   return A
end

