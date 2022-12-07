module ObjectPools

function acquire! end 
function release! end 

using Base.Threads: threadid, nthreads
using DataStructures: Stack 

export acquire!, 
       release!

include("arraycache.jl")     

include("temparray.jl")

# this isn't yet completed 
include("flexarraycache.jl")

end
