module ObjectPools

function acquire! end 
function release! end 

using Base.Threads: threadid, nthreads
using DataStructures: Stack 

export acquire!, 
       release!

include("arraycache.jl")     

include("temparray.jl")

include("flexarraycache.jl")

include("flextemparray.jl")

end
