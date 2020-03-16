module Float8s

    import Base: (-),(==),(<),(<=),isless,bitstring,
                isnan,iszero,one,zero,abs,isfinite,
                floatmin,floatmax,typemin,typemax,
                Float16,Float32,Float64,
                UInt8,Int8,Int16,Int32,Int64,
                (+), (-), (*), (/), (\), (^),
                sin,cos,tan,asin,acos,atan,sinh,cosh,tanh,asinh,acosh,
                atanh,exp,exp2,exp10,expm1,log,log2,log10,sqrt,cbrt,log1p,
                atan,hypot,round,show,nextfloat,prevfloat,
                promote_rule, sign, signbit

    export Float8, Float8_4, NaN8, Inf8, NaN8_4, Inf8_4

    include("float8.jl")
    include("float8_to_float32.jl")
    include("float32_to_float8.jl")
    include("float32_to_float8_old.jl")

end
