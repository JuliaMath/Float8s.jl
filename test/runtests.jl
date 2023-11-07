using Float8s
using Test

@testset "Float8 -> Float32 ordered?" begin
    @testset for i in 0x00:UInt8(floatmax(Float8))
        f1 = Float32(Float8(i))
        f2 = Float32(Float8(i+0x1))
        @test f2 > f1
    end

    @testset for i in 0x80:UInt8(-floatmax(Float8))
        f1 = Float32(Float8(i))
        f2 = Float32(Float8(i+0x1))
        @test f2 < f1
    end
end

@testset "Float8_4 -> Float32 ordered?" begin
    @testset for i in 0x00:UInt8(floatmax(Float8_4))
        f1 = Float32(Float8_4(i))
        f2 = Float32(Float8_4(i+0x1))
        @test f2 > f1
    end

    @testset for i in 0x80:UInt8(-floatmax(Float8_4))
        f1 = Float32(Float8_4(i))
        f2 = Float32(Float8_4(i+0x1))
        @test f2 < f1
    end
end

@testset "Float32 -> Float8 non-subnormals ordered?" begin

    N = 100

    fs = (Float32(floatmax(Float8))-Float32(floatmin(Float8)))*rand(Float32,N) .+ Float32(floatmin(Float8))
    sort!(fs)

    f8s = Float8.(fs)
    @testset for i in 1:N-1
        @test f8s[i+1] >= f8s[i]
    end

    f8s = Float8.(-fs)
    @testset for i in 1:N-1
        @test f8s[i+1] <= f8s[i]
    end
end

@testset "Float32 -> Float8 subnormals ordered?" begin

    N = 100

    fs = Float32(floatmin(Float8))*rand(Float32,N)
    sort!(fs)

    f8s = Float8.(fs)
    @testset for i in 1:N-1
        @test f8s[i+1] >= f8s[i]
    end

    f8s = Float8.(-fs)
    @testset for i in 1:N-1
        @test f8s[i+1] <= f8s[i]
    end
end


@testset "Conversion Float8 <-> Float32" begin

    @testset for i in 0x00:0xff
        if ~isnan(Float8(i))
            @test i == reinterpret(UInt8,Float8(Float32(Float8(i))))
        end
    end
end

# Currently not implemented
# @testset "Conversion Float8_4 <-> Float32" begin
#
#     @testset for i in 0x00:0xff
#         if ~isnan(Float8_4(i))
#             @test i == reinterpret(UInt8,Float8_4(Float32(Float8_4(i))))
#         end
#     end
# end

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
    @test !isnan(Float8(2.6))
    @test NaN8 != NaN8

    @test isinf(Inf8)
    @test isinf(-Inf8)
    @test !isinf(NaN8)
    @test !isinf(-NaN8)
    @test !isinf(Float8(2.6))
    @test Inf8 == Inf8
    @test Inf8 != -Inf8
    @test -Inf8 < Inf8
end

@testset "NaN8_4 and Inf8_4" begin
    @test isnan(NaN8_4)
    @test isnan(-NaN8_4)
    @test !isnan(Inf8_4)
    @test !isnan(-Inf8_4)
    @test !isnan(Float8(2.6))
    @test NaN8_4 != NaN8_4

    @test isinf(Inf8_4)
    @test isinf(-Inf8_4)
    @test !isinf(NaN8_4)
    @test !isinf(-NaN8_4)
    @test !isinf(Float8(2.6))
    @test Inf8_4 == Inf8_4
    @test Inf8_4 != -Inf8_4
    @test -Inf8_4 < Inf8_4
end

@testset "Nextfloat" begin
    for i in 0x00:0xff

        f = Float8(i)
        if isfinite(f)
            @test f < nextfloat(f)
            #@test 0x1 == UInt8(nextfloat(f))-i     # this is only true for positive numbers
        end

        f = Float8_4(i)
        if isfinite(f)
            @test f < nextfloat(f)
            #@test 0x1 == UInt8(nextfloat(f))-i     # this is only true for positive numbers
        end
    end

    @test NaN8 != nextfloat(NaN8)
    @test Inf8 == nextfloat(Inf8)
    @test -floatmax(Float8) == nextfloat(-Inf8)

    @test NaN8_4 != nextfloat(NaN8_4)
    @test Inf8_4 == nextfloat(Inf8_4)
    @test -floatmax(Float8_4) == nextfloat(-Inf8_4)

    for T in (Float8, Float8_4)
        @test eps(T) == nextfloat(T(1)) - T(1)
        @test eps(one(T)) == eps(T)
    end
end

@testset "Prevfloat" begin
    for i in 0x00:0xff

        f = Float8(i)
        if isfinite(f)
            @test f > prevfloat(f)
            # @test 0x1 == i-UInt8(prevfloat(f))    # this is only true for positive numbers
        end

        f = Float8_4(i)
        if isfinite(f)
            @test f > prevfloat(f)
            # @test 0x1 == i-UInt8(prevfloat(f))    # this is only true for positive numbers
        end
    end

    @test NaN8 != prevfloat(NaN8)
    @test Inf8 > prevfloat(Inf8)
    @test NaN8_4 != prevfloat(NaN8_4)
    @test Inf8_4 > prevfloat(Inf8_4)

    @test -zero(Float8) > prevfloat(-zero(Float8))
    @test -zero(Float8_4) > prevfloat(-zero(Float8_4))

    @test zero(Float8) > prevfloat(zero(Float8))
    @test zero(Float8_4) > prevfloat(zero(Float8_4))

    @test prevfloat(zero(Float8)) == prevfloat(-zero(Float8))
    @test prevfloat(zero(Float8_4)) == prevfloat(-zero(Float8_4))

    @test -Inf8 == prevfloat(-Inf8)
    @test -Inf8_4 == prevfloat(-Inf8_4)
end

@testset "Signbit" begin

    for i in 0x00:0x7f      # positive numbers
        @test ~signbit(Float8(i))
        @test ~signbit(Float8_4(i))
    end

    for i in 0x80:0xff      # positive numbers
        @test signbit(Float8(i))
        @test signbit(Float8_4(i))
    end

end

@testset "Sign" begin

    for i in 0x01:0x7f

        f = Float8(i)
        if isnan(f)
            @test UInt8(f) == UInt8(sign(f))    # NaN == NaN yields false but the bitpattern are identical
        else
            @test one(f) == sign(f)
        end

        f = Float8_4(i)
        if isnan(f)
            @test UInt8(f) == UInt8(sign(f))    # NaN == NaN yields false but the bitpattern are identical
        else
            @test one(f) == sign(f)
        end
    end

    for i in 0x81:0xff

        f = Float8(i)
        if isnan(f)
            @test UInt8(f) == UInt8(sign(f))    # NaN == NaN yields false but the bitpattern are identical
        else
            @test -one(f) == sign(f)
        end

        f = Float8_4(i)
        if isnan(f)
            @test UInt8(f) == UInt8(sign(f))    # NaN == NaN yields false but the bitpattern are identical
        else
            @test -one(f) == sign(f)
        end
    end

    @test zero(Float8) == sign(zero(Float8))
    @test zero(Float8_4) == sign(zero(Float8_4))

    @test -zero(Float8) == sign(-zero(Float8))
    @test -zero(Float8_4) == sign(-zero(Float8_4))
end

@testset "Promotion" begin
    @test Float8(2)*Float16(2) == Float16(4)
    @test Float8(2)*Float32(2) == Float32(4)
    @test Float8(2)*Float64(2) == Float64(4)

    @test true*Float8(2) == Float8(2)
    @test false*Float8(2) == zero(Float8)
    @test 2*Float8(2) == Float8(4)
end
