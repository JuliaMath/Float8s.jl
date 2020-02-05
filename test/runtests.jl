using Float8s
using Test

@testset "Compare to Float32" begin

    n = 256

    @testset "Addition" begin
        for i in 0:n-1
            for j in 0:n-1
                x = Float8(UInt8(i))
                y = Float8(UInt8(j))

                @test x+y == Float8(Float32(x)+Float32(y)) || isnan(x) && isnan(y)
            end
        end
    end
end
