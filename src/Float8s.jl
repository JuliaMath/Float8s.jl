module Float8s

    import Base: (-),(==),(<),(<=),isless,bitstring,
                isnan,iszero,one,zero,abs,isfinite,
                floatmin,floatmax,typemin,typemax,
                Float16,Float32,Float64,
                UInt8,Int8,Int16,Int32,Int64

    export Float8, Float8_4, NaN8, Inf8

    include("float8.jl")

end
