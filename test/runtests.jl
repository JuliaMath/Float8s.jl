using Float8s
using Test

@testset "Conversion Float8 <-> Float32" begin

    for i in 0x00:0xff
        if ~isnan(Float8(i))
            @test i == reinterpret(UInt8,Float8(Float32(Float8(i))))
        end
    end
end

@testset "Conversion Float8 <-> Float32" begin

    for i in 0x00:0xff
        if ~isnan(Float8_4(i))
            @test i == reinterpret(UInt8,Float8_4(Float32(Float8_4(i))))
        end
    end
end
