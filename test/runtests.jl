using Float8s
using Test

@testset "Conversion to Float32" begin

    for i in 0x10:0x80
        @test i == reinterpret(UInt8,Float8(Float32(Float8(i))))
    end
end
