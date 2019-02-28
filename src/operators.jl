# Concrete "under the hood" methods.
# (NoBoundary, NoBoundary)
function DifferentialOperator(x, bc::Tuple{NoBoundary, NoBoundary}, method::DifferenceMethod)
    T = eltype(x)
    d = diff(x)
    Δ_1 = d[1]
    Δ_M = d[end]
    M = length(x)

    # get basis operator on interior nodes
    L_basis = get_basis_operator(x, method)

    # add columns for ghost nodes next to boundaries
    col_lb = zeros(T, M)
    col_ub = zeros(T, M)
    col_lb[1] = typeof(method) <: BackwardFirstDifference ? -(one(T) / Δ_1) : zero(T)
    col_lb[1] = typeof(method) <: CentralSecondDifference ? (one(T) / (Δ_1*Δ_1)) : col_lb[1]
    col_ub[end] = typeof(method) <: ForwardFirstDifference ? (one(T) / Δ_M) : zero(T)
    col_ub[end] = typeof(method) <: CentralSecondDifference ? (one(T) / (Δ_M*Δ_M)) : col_ub[end]

    L = sparse([col_lb L_basis col_ub])
end

# (Reflecting, Reflecting)
function DifferentialOperator(x, bc::Tuple{Reflecting, Reflecting}, method::DifferenceMethod)
    T = eltype(x)

    # get basis operator on interior nodes
    L = get_basis_operator(x, method)

    # apply boundary conditions
    L[1,1] = typeof(method) <: BackwardFirstDifference ? zero(T) : L[1,1]
    L[1,1] = typeof(method) <: CentralSecondDifference ? (L[1,1] / 2) : L[1,1]
    L[end,end] = typeof(method) <: ForwardFirstDifference ? zero(T) : L[end,end]
    L[end,end] = typeof(method) <: CentralSecondDifference ? (L[end,end] / 2) : L[end,end] 

    return L
end

# (Mixed, Mixed)
function DifferentialOperator(x, bc::Tuple{Mixed, Mixed}, method::DifferenceMethod)
    T = eltype(x)
    d = diff(x)
    Δ_1 = d[1]
    Δ_M = d[end]
    ξ_lb = bc[1].ξ
    ξ_ub = bc[2].ξ

    # get basis operator on interior nodes
    L = DifferentialOperator(x, (Reflecting(), Reflecting()), method)

    # apply boundary conditions
    L[1,1] -= typeof(method) <: BackwardFirstDifference ? ξ_lb : zero(T)
    L[1,1] += typeof(method) <: CentralSecondDifference ? (ξ_lb / Δ_1) : zero(T)
    L[end,end] -= typeof(method) <: ForwardFirstDifference ? ξ_ub : zero(T)
    L[end,end] -= typeof(method) <: CentralSecondDifference ? (ξ_ub / Δ_M) : zero(T) 

    return L
end

# Convenience calls
L₁₋(x, bc) = DifferentialOperator(x, bc, BackwardFirstDifference())
L₁₊(x, bc) = DifferentialOperator(x, bc, ForwardFirstDifference())
L₂(x, bc) = DifferentialOperator(x, bc, CentralSecondDifference())

L̄₁₋(x) = DifferentialOperator(x, (NoBoundary(), NoBoundary()), BackwardFirstDifference())
L̄₁₊(x) = DifferentialOperator(x, (NoBoundary(), NoBoundary()), ForwardFirstDifference())
L̄₂(x)  = DifferentialOperator(x, (NoBoundary(), NoBoundary()), CentralSecondDifference())

function x̄(x)
    d = diff(x) # dispatches based on AbstractArray or not
    x̄ = collect([x[1] - d[1]; x; x[end] + d[end]])
end

"""
    `diffusionoperators(x, bc::Tuple{BoundaryCondition, BoundaryCondition})`
Returns a tuple of diffusion operators and extended grid `(L₁₋, L₁₊, L₂, x̄)`
with specified boundary conditions.
Given a grid `x` of length `M`, return diffusion operators for negative drift, positive drift,
and central differences. 
The first element of `bc` is applied to the lower bound, and second element of `bc` to the upper. 
`x̄` is a `(M+2)` array that
represents the extended grid whose first and last elements represent the ghost nodes
just before `x[1]` and `x[end]`.
# Examples
```jldoctest; setup = :(using SimpleDifferentialOperators)
julia> x = 1:3
1:3

julia> L₁₋, L₁₊, L₂, x̄ = diffusionoperators(x, (Reflecting(), Reflecting()));

julia> Array(L₁₋)
3×3 Array{Float64,2}:
  0.0   0.0  0.0
 -1.0   1.0  0.0
  0.0  -1.0  1.0

julia> Array(L₁₊)
3×3 Array{Float64,2}:
 -1.0   1.0  0.0
  0.0  -1.0  1.0
  0.0   0.0  0.0

julia> Array(L₂)
3×3 Array{Float64,2}:
 -1.0   1.0   0.0
  1.0  -2.0   1.0
  0.0   1.0  -1.0

julia> 

julia> x̄
5-element Array{Int64,1}:
 0
 1
 2
 3
 4

julia> L̄₁₋, L̄₁₊, L̄₂, x̄ = diffusionoperators(x, (NoBoundary(), NoBoundary()));
    
julia> Array(L̄₁₋)
3×5 Array{Float64,2}:
    -1.0   1.0   0.0  0.0  0.0
    0.0  -1.0   1.0  0.0  0.0
    0.0   0.0  -1.0  1.0  0.0

julia> Array(L̄₁₊)
3×5 Array{Float64,2}:
    0.0  -1.0   1.0   0.0  0.0
    0.0   0.0  -1.0   1.0  0.0
    0.0   0.0   0.0  -1.0  1.0

julia> Array(L̄₂)
3×5 Array{Float64,2}:
    1.0  -2.0   1.0   0.0  0.0
    0.0   1.0  -2.0   1.0  0.0
    0.0   0.0   1.0  -2.0  1.0

julia> Array(x̄)
5-element Array{Int64,1}:
    0
    1
    2
    3
    4
```
"""
diffusionoperators(x, bc) = (L₁₋ = L₁₋(x, bc), L₁₊ = L₁₊(x, bc), L₂ = L₂(x, bc), x̄ = x̄(x))
