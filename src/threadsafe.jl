
struct ThreadSafe{T}
   t::Vector{T} 
end

ThreadSafe(t1) = ThreadSafe( [ deepcopy(t1) for _ = 1:nthreads() ] )

function acquire!(c::ThreadSafe, args...)
   tid = threadid()
   return acquire!(c.t[tid], args...)
end
