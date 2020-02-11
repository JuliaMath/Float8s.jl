using Float8s
using Test

@testset "Conversion to Float32" begin

    for i in 0x00:0xff
        if ~isnan(Float8(i))
            @test i == reinterpret(UInt8,Float8(Float32(Float8(i))))
        end
    end
end
