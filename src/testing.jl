
module Testing

using ObjectPools: acquire!, release!, FlexArray, FlexArrayCache, ArrayPool, TSafe


function chebbasis!(T, x::Real) 
   N = length(T) 
   @assert N > 2
   @inbounds begin 
      T[1] = one(x) 
      T[2] = x 
      for n = 3:N 
         T[n] = 2x*T[n-1] - T[n-2] 
      end
   end
   return T
end

function chebbasis!(T, X::AbstractVector{<: Real}) 
   NX = length(X) 
   NT = size(T, 2)
   @assert size(T, 1) >= NX
   @assert NT > 2
   @inbounds begin 
      @simd ivdep for i = 1:NX 
         T[i, 1] = one(eltype(X)) 
         T[i, 2] = X[i]
      end
      for n = 3:NT 
         @simd ivdep for i = 1:NX
            T[i, n] = 2X[i]*T[i, n-1] - T[i, n-2]
         end
      end
   end
   return T
end



function chebbasis(::Nothing, x::Real, N) 
   return chebbasis!(zeros(N), x)
end

function chebbasis(A::Vector, x::Real, N) 
   @assert length(A) == N
   return chebbasis!(A, x)
end

function chebbasis(pool::Union{ArrayPool, TSafe{<: ArrayPool}}, x::Real, N) 
   T = acquire!(pool, :T, (N,), typeof(x))
   chebbasis!(parent(T), x) 
   return T 
end

function chebbasis(temp::Union{FlexArray, FlexArrayCache, TSafe}, x::Real, N)
   T = acquire!(temp, (N,), typeof(x))
   chebbasis!(parent(T), x) 
   return T 
end

function chebbasis(::Nothing, X::AbstractVector{<: Real}, N) 
   return chebbasis!(zeros(length(X), N), X)
end

function chebbasis(A::Matrix, X::AbstractVector{<: Real}, N) 
   @assert size(A) == (length(X), N)
   return chebbasis!(A, X)
end

function chebbasis(pool::Union{ArrayPool, TSafe{<: ArrayPool}}, X::AbstractVector{<: Real}, N) 
   T = acquire!(pool, :T, (length(X), N), eltype(X))
   chebbasis!(parent(T), X) 
   return T 
end

function chebbasis(temp::Union{FlexArray, FlexArrayCache, TSafe}, X::AbstractVector{<: Real}, N) 
   T = acquire!(temp, (length(X), N), eltype(X))
   chebbasis!(parent(T), X) 
   return T 
end


end 