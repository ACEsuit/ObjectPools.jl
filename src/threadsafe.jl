
struct TSafe{T}
   t::Vector{T} 
end

TSafe(t1) = TSafe( [ deepcopy(t1) for _ = 1:nthreads() ] )

function acquire!(c::TSafe, args...)
   tid = threadid()
   return acquire!(c.t[tid], args...)
end
