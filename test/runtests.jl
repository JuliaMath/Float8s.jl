using .Float8s
using Test

@testset "Conversion Float8 <-> Float32" begin

    @testset for i in 0x00:0xff
        if ~isnan(Float8(i))
            @test i == reinterpret(UInt8,Float8(Float32(Float8(i))))
        end
    end
end

@testset "Conversion Float8_4 <-> Float32" begin

    @testset for i in 0x00:0xff
        if ~isnan(Float8_4(i))
            @test i == reinterpret(UInt8,Float8_4(Float32(Float8_4(i))))
        end
    end
end

@testset "Negation" begin

    @testset for i in 0x00:0xff
        f8 = Float8(i)
        f8_4 = Float8_4(i)

        if ~isnan(f8)
            @test f8 == -(-f8)
        end

        if ~isnan(f8_4)
            @test f8_4 == -(-f8_4)
        end
    end
end

@testset "Rounding" begin

    @testset for i in 0x00:0xff
        f8 = Float8(i)
        f8_4 = Float8_4(i)

        if ~isnan(f8)
            @test f8 >= floor(f8)
            @test f8 <= ceil(f8)
        end

        if ~isnan(f8_4)
            @test f8_4 >= floor(f8_4)
            @test f8_4 <= ceil(f8_4)
        end
    end
end

@testset "Triangle inequality Float8" begin

    @testset for i in 0x00:0xff
        for j in 0x00:0xff

            f1 = Float8(i)
            f2 = Float8(j)

            if ~isnan(f1) && ~isnan(f2) && isfinite(f1) && isfinite(f2)
                @test abs(f1) + abs(f2) >= abs(f1+f2)
                @test abs(f1) - abs(f2) <= abs(f1-f2)
                @test abs(f1) * abs(f2) >= f1*f2
            end
        end
    end
end

@testset "Triangle inequality Float8_4" begin

    @testset for i in 0x00:0xff
        for j in 0x00:0xff

            f1 = Float8_4(i)
            f2 = Float8_4(j)

            if ~isnan(f1) && ~isnan(f2) && isfinite(f1) && isfinite(f2)
                @test abs(f1) + abs(f2) >= abs(f1+f2)
                @test abs(f1) - abs(f2) <= abs(f1-f2)
                @test abs(f1) * abs(f2) >= f1*f2
            end
        end
    end
end

f = Float8(2.)
g = Float8(1.)

@testset "Comparison Float8" begin
    @test f >= g
    @test f > g
    @test g < f
    @test g <= g
    @test all([g g] .< [f f])
    @test all([g g] .<= [f f])
    @test all([f f] .> [g g])
    @test all([f f] .>= [g g])
    @test isless(g, f)
    @test !isless(f, g)

    @test Float8(2.5) == Float8(2.5)
    @test Float8(2.5) != Float8(2.6)
end

f = Float8_4(2.)
g = Float8_4(1.)

@testset "Comparison Float8_4" begin
    @test f >= g
    @test f > g
    @test g < f
    @test g <= g
    @test all([g g] .< [f f])
    @test all([g g] .<= [f f])
    @test all([f f] .> [g g])
    @test all([f f] .>= [g g])
    @test isless(g, f)
    @test !isless(f, g)

    @test Float8_4(2.5) == Float8_4(2.5)
    @test Float8_4(2.5) != Float8_4(2.7)
end

@testset "NaN8 and Inf8" begin
    @test isnan(NaN8)
    @test isnan(-NaN8)
    @test !isnan(Inf8)
    @test !isnan(-Inf8)
    @test !isnan(Float16(2.6))
    @test NaN8 != NaN8
    @test repr(NaN8) == "NaN8"

    @test isinf(Inf8)
    @test isinf(-Inf8)
    @test !isinf(NaN8)
    @test !isinf(-NaN8)
    @test !isinf(Float16(2.6))
    @test Inf8 == Inf8
    @test Inf8 != -Inf8
    @test -Inf8 < Inf8
    @test repr(Inf8) == "Inf8"
end

@testset "NaN8_4 and Inf8_4" begin
    @test isnan(NaN8_4)
    @test isnan(-NaN8_4)
    @test !isnan(Inf8_4)
    @test !isnan(-Inf8_4)
    @test !isnan(Float8(2.6))
    @test NaN8_4 != NaN8_4
    @test repr(NaN8_4) == "NaN8_4"

    @test isinf(Inf8_4)
    @test isinf(-Inf8_4)
    @test !isinf(NaN8_4)
    @test !isinf(-NaN8_4)
    @test !isinf(Float8(2.6))
    @test Inf8_4 == Inf8_4
    @test Inf8_4 != -Inf8_4
    @test -Inf8_4 < Inf8_4
    @test repr(Inf8_4) == "Inf8_4"
end
