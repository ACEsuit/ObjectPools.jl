


struct ArrayPool{TP}
   arrays::Dict{Symbol, TP}
end

ArrayPool(TP::Type) = ArrayPool(Dict{Symbol, TP}())

function acquire!(pool::ArrayPool{TP}, 
                  name::Symbol, 
                  sz::NTuple{N, <: Integer}, 
                  ::Type{T}   ) where {TP, T, N}
   if !haskey(pool.arrays, name)
      pool.arrays[name] = TP()
   end
   return acquire!(pool.arrays[name], sz, T)
end
