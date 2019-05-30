@testset "Accuracy test for Laffine" begin
    regular_grids = [0:4, -1:6]
    irregular_grids = [[-1.0; 0.0; 2.0; 5.0; 9.0], [0.2; 0.3; 0.5; 0.9; 1.6; 2.5]]
    for x̄ in [regular_grids; irregular_grids], 
        (L_bc_generator, L_generator, L_affine_generator) in [(L₁₋bc, L₁₋, L₁₋affine), (L₁₊bc, L₁₊, L₁₊affine), (L₂bc, L₂, L₂affine)],
        (S_lower, S_upper) in [(0.0, 1.0), (1.0, 0.0), (1.5, -1.5), (1.2, 1.3), (1.0, 1.0)]
        # Setup
        # RHS function
        f(x) = x^2

        # grid setup
        # x̄ = 0:4
        x = interiornodes(x̄)
        M = length(x)
        Δ_0p = x̄[2] - x̄[1] 
        Δ_Mp = x̄[end] - x̄[end-1]

        # boundary condition
        bc = (NonhomogeneousAbsorbing(S_lower), NonhomogeneousAbsorbing(S_upper))

        # corresponding boundary condition matrix
        B = transpose([[1; zeros(M+1)] [zeros(M+1); 1]])
        b = [S_lower; S_upper]

        # operator on the interior, with bc applied 
        L_bc = L_bc_generator(x̄, bc)
        # operator on the exterior
        L = L_generator(x̄)

        # solution for interior v from L_bc
        v_bc = L_bc \ (f.(x) + L_affine_generator(x̄, bc))
        # solution for interior v from L_bc, using Laffine
        v_bc_Laffine = L_bc \ (f.(x) + Laffine(L, bc))
        # solution for extended v from L by stacking up boundary condition matrices
        v̄ = [L; B] \ [f.(x); b]

        # test if extrapolated solutions are identical
        @test extrapolatetoboundary(v_bc, x̄, bc) ≈ v̄ 
        @test extrapolatetoboundary(v_bc_Laffine, x̄, bc) ≈ v̄ 
        
    end
end