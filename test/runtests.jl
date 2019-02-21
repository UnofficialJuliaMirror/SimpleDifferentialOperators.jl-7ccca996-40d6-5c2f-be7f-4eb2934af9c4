using SimpleDifferentialOperators
using Test, LinearAlgebra, DualNumbers

@testset "Dispatch Tests" begin
    methodList = collect(methods(SimpleDifferentialOperators._diffusionoperators))

    # Test for defined cases
    @test which(SimpleDifferentialOperators._diffusionoperators, (AbstractRange, Reflecting, Reflecting)) == methodList[1]
    @test which(SimpleDifferentialOperators._diffusionoperators, (AbstractRange, Mixed, Mixed)) == methodList[2]
    @test which(SimpleDifferentialOperators._diffusionoperators, (AbstractArray, Reflecting, Reflecting)) == methodList[1]
    @test which(SimpleDifferentialOperators._diffusionoperators, (AbstractArray, Mixed, Mixed)) == methodList[2]

    # Test for error handling
    grids = [range(1.0, 10.0, length = 100), collect(range(1.0, 10.0, length = 100))]
    BCs = [Reflecting(), Mixed(2.0), Absorbing(1.0, 2.0)] # list of all possible BCs
    @test_throws MethodError diffusionoperators(grids[1], BCs[1], BCs[3])
    @test_throws MethodError diffusionoperators(grids[2], BCs[1], BCs[2])
end

@testset "Reflecting Barrier Tests" begin
    #=
        Correctness tests
    =#
    σ = 1; μ = -1;
    # Uniform grid
    L_1_minus, L_1_plus, L_2 = diffusionoperators(1:5, Reflecting(), Reflecting())
    @test @inferred(diffusionoperators(1:5, Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    @test @inferred(diffusionoperators(1:5, Mixed(0.), Mixed(0.))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2) # test that the mixed case properly nests the reflecting case
    @test μ * L_1_minus + σ^2/2 * L_2 == [-0.5 0.5 0.0 0.0 0.0; 1.5 -2.0 0.5 0.0 0.0; 0.0 1.5 -2.0 0.5 0.0; 0.0 0.0 1.5 -2.0 0.5; 0.0 0.0 0.0 1.5 -1.5]
    @test -μ * L_1_plus + σ^2/2 * L_2 == [-1.5 1.5 0.0 0.0 0.0; 0.5 -2.0 1.5 0.0 0.0; 0.0 0.50 -2.0 1.50 0.0; 0.0 0.0 0.50 -2.0 1.50; 0.0 0.0 0.0 0.50 -0.50]
    # Irregular grid
    L_1_minus, L_1_plus, L_2 = diffusionoperators(collect(1:5), Reflecting(), Reflecting()) # irregular grid
    @test @inferred(diffusionoperators(collect(1:5), Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    @test @inferred(diffusionoperators(collect(1:5), Mixed(0.), Mixed(0.))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    @test μ * L_1_minus + σ^2/2 * L_2 == [-0.5 0.5 0.0 0.0 0.0; 1.5 -2.0 0.5 0.0 0.0; 0.0 1.5 -2.0 0.5 0.0; 0.0 0.0 1.5 -2.0 0.5; 0.0 0.0 0.0 1.5 -1.5]
    @test -μ * L_1_plus + σ^2/2 * L_2 == [-1.5 1.5 0.0 0.0 0.0; 0.5 -2.0 1.5 0.0 0.0; 0.0 0.50 -2.0 1.50 0.0; 0.0 0.0 0.50 -2.0 1.50; 0.0 0.0 0.0 0.50 -0.50]

    #=
        Consistency tests
    =#
    uniformGrid = range(0.0, 1.0, length = 500)
    irregularGrid = collect(uniformGrid)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Reflecting(), Reflecting())
    L_1_minus_ir, L_1_plus_ir, L_2_ir = diffusionoperators(irregularGrid, Reflecting(), Reflecting())
    @test L_1_minus ≈ L_1_minus_ir
    @test L_1_plus ≈ L_1_plus_ir
    @test L_2 ≈ L_2_ir
end

@testset "Mixed Boundary Tests" begin
    σ = 1; μ = -1;
    uniformGrid = 1:1:5
    irregularGrid = collect(uniformGrid)
    ξ_1, ξ_2 = (1., 2.)
    #=
        Accuracy tests
    =#
    ξ = ξ_1
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Mixed(ξ), Mixed(ξ))
    @test @inferred(diffusionoperators(uniformGrid, Mixed(ξ), Mixed(ξ))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    @test μ * L_1_minus + σ^2/2 * L_2 == [-1+(1+ξ)+(-2+1+ξ)/2 0.5 0.0 0.0 0.0; 1.5 -2.0 0.5 0.0 0.0; 0.0 1.5 -2.0 0.5 0.0; 0.0 0.0 1.5 -2.0 0.5; 0.0 0.0 0.0 1.5 -1+(-2+1-ξ)/2]
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Mixed(ξ), Mixed(ξ))
    @test @inferred(diffusionoperators(irregularGrid    , Mixed(ξ), Mixed(ξ))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    @test μ * L_1_minus + σ^2/2 * L_2 == [-1+(1+ξ)+(-2+1+ξ)/2 0.5 0.0 0.0 0.0; 1.5 -2.0 0.5 0.0 0.0; 0.0 1.5 -2.0 0.5 0.0; 0.0 0.0 1.5 -2.0 0.5; 0.0 0.0 0.0 1.5 -1+(-2+1-ξ)/2]

    ξ = ξ_2
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Mixed(ξ), Mixed(ξ))
    @test @inferred(diffusionoperators(uniformGrid, Mixed(ξ), Mixed(ξ))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    @test μ * L_1_minus + σ^2/2 * L_2 == [-1+(1+ξ)+(-2+1+ξ)/2 0.5 0.0 0.0 0.0; 1.5 -2.0 0.5 0.0 0.0; 0.0 1.5 -2.0 0.5 0.0; 0.0 0.0 1.5 -2.0 0.5; 0.0 0.0 0.0 1.5 -1+(-2+1-ξ)/2]
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Mixed(ξ), Mixed(ξ))
    @test @inferred(diffusionoperators(irregularGrid, Mixed(ξ), Mixed(ξ))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    @test μ * L_1_minus + σ^2/2 * L_2 == [-1+(1+ξ)+(-2+1+ξ)/2 0.5 0.0 0.0 0.0; 1.5 -2.0 0.5 0.0 0.0; 0.0 1.5 -2.0 0.5 0.0; 0.0 0.0 1.5 -2.0 0.5; 0.0 0.0 0.0 1.5 -1+(-2+1-ξ)/2]

    #=
        Consistency tests
    =#
    uniformGrid = range(0.0, 1.0, length = 500)
    irregularGrid = collect(uniformGrid)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Mixed(ξ_1), Mixed(ξ_2))
    L_1_minus_ir, L_1_plus_ir, L_2_ir = diffusionoperators(irregularGrid, Mixed(ξ_1), Mixed(ξ_2))
    @test L_1_minus ≈ L_1_minus_ir
    @test L_1_plus ≈ L_1_plus_ir
    @test L_2 ≈ L_2_ir
end


@testset "Interior without boundary conditions" begin
    uniform_grid = 1:1:2
    irregular_grid = collect(uniform_grid)
    # test for accuracy
    ## regular grids
    L_1_minus, L_1_plus, L_2, x_bar = diffusionoperators(uniform_grid, NoBoundary())
    @test Array(L_1_minus) == [-1. 1. 0. 0.; 0. -1. 1. 0.]
    @test Array(L_1_plus) == [0. -1. 1. 0.; 0. 0. -1. 1.]
    @test Array(L_2) == [1. -2. 1. 0.; 0. 1. -2. 1.]
    @test Array(x_bar) == [0; 1; 2; 3]
    @test @inferred(diffusionoperators(uniform_grid, NoBoundary())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2, x_bar = x_bar)

    ## irregular grids
    L_1_minus, L_1_plus, L_2, x_bar = diffusionoperators(irregular_grid, NoBoundary())
    @test Array(L_1_minus) == [-1. 1. 0. 0.; 0. -1. 1. 0.]
    @test Array(L_1_plus) == [0. -1. 1. 0.; 0. 0. -1. 1.]
    @test Array(L_2) == [1. -2. 1. 0.; 0. 1. -2. 1.]
    @test Array(x_bar) == [0; 1; 2; 3]
    @test @inferred(diffusionoperators(irregular_grid, NoBoundary())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2, x_bar = x_bar)
end

@testset "Input Type Variance" begin
    # BigFloat
    uniformGrid = range(BigFloat(0.0), BigFloat(1.0), length = 100)
    irregularGrid = collect(uniformGrid)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Reflecting(), Reflecting())
    @test @inferred(diffusionoperators(uniformGrid, Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Reflecting(), Reflecting())
    @test @inferred(diffusionoperators(irregularGrid, Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Mixed(one(BigFloat)), Mixed(one(BigFloat)))
    @test @inferred(diffusionoperators(uniformGrid, Mixed(one(BigFloat)), Mixed(one(BigFloat)))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Mixed(one(BigFloat)), Mixed(one(BigFloat)))
    @test @inferred(diffusionoperators(irregularGrid, Mixed(one(BigFloat)), Mixed(one(BigFloat)))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)

    # Float32
    uniformGrid = range(Float32(0.0), Float32(1.0), length = 100)
    irregularGrid = collect(uniformGrid)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Reflecting(), Reflecting())
    @test @inferred(diffusionoperators(uniformGrid, Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Reflecting(), Reflecting())
    @test @inferred(diffusionoperators(irregularGrid, Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Mixed(one(Float32)), Mixed(one(Float32)))
    @test @inferred(diffusionoperators(uniformGrid, Mixed(one(BigFloat)), Mixed(one(BigFloat)))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Mixed(one(Float32)), Mixed(one(Float32)))
    @test @inferred(diffusionoperators(irregularGrid, Mixed(one(BigFloat)), Mixed(one(BigFloat)))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)

    # Duals
    uniformGrid = range(Dual(0.0), Dual(1.0), length = 100)
    irregularGrid = collect(uniformGrid)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Reflecting(), Reflecting())
    @test @inferred(diffusionoperators(uniformGrid, Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Reflecting(), Reflecting())
    @test @inferred(diffusionoperators(irregularGrid, Reflecting(), Reflecting())) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(uniformGrid, Mixed(Dual(1.0)), Mixed(Dual(1.0)))
    @test @inferred(diffusionoperators(uniformGrid, Mixed(Dual(1.0)), Mixed(Dual(1.0)))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
    L_1_minus, L_1_plus, L_2 = diffusionoperators(irregularGrid, Mixed(Dual(1.0)), Mixed(Dual(1.0)))
    @test @inferred(diffusionoperators(irregularGrid, Mixed(Dual(1.0)), Mixed(Dual(1.0)))) == (L_1_minus = L_1_minus, L_1_plus = L_1_plus, L_2 = L_2)
end
