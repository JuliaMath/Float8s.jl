abstract type AbstractFloat8 <: AbstractFloat end
primitive type Float8 <: AbstractFloat8 8 end        # standard 3 exp version
primitive type Float8_4 <: AbstractFloat8 8 end      # version with 4 exp bits

# conversions
Float8(x::UInt8) = reinterpret(Float8,x)
Float8_4(x::UInt8) = reinterpret(Float8_4,x)
UInt8(x::T) where {T<:AbstractFloat8} = reinterpret(UInt8,x)
bitstring(x::AbstractFloat8) = bitstring(reinterpret(UInt8,x))
Float8(x::T) where {T<:Union{Int16,Int32,Int64,Float64,Float16}} = Float8(Float32(x))
Float8_4(x::T) where {T<:Union{Int16,Int32,Int64,Float64,Float16}} = Float8_4(Float32(x))
(::Type{T})(x::AbstractFloat8) where {T<:Union{Int16,Int32,Int64,Float64,Float16}} = T(Float32(x))

# masks, UInt8s with 1s for the respective parts
sign_mask(::Type{T}) where {T<:AbstractFloat8} = 0x80
exponent_mask(::Type{Float8}) = 0x70
exponent_mask(::Type{Float8_4}) = 0x78
significand_mask(::Type{Float8}) = 0x0f
significand_mask(::Type{Float8_4}) = 0x07

sign_mask(::Type{Float32}) =            0x8000_0000
exponent_mask(::Type{Float32}) =        0x7f80_0000
significand_mask(::Type{Float32}) =     0x007f_ffff
n_exponent_bits(::Type{Float32}) =      8
n_significant_bits(::Type{Float32}) =   23

# number of exp/sig bits
n_exponent_bits(::Type{Float8}) = 3
n_exponent_bits(::Type{Float8_4}) = 4
n_significant_bits(::Type{Float8}) = 4
n_significant_bits(::Type{Float8_4}) = 3
bias(::Type{Float8}) = 3
bias(::Type{Float8_4}) = 7

eps(x::AbstractFloat8) = max(x-prevfloat(x), nextfloat(x)-x)
eps(::Type{T}) where T <: AbstractFloat8 = eps(one(T))

# define inifinities and nan
inf8(::Type{Float8}) = Float8(0x70)
inf8(::Type{Float8_4}) = Float8_4(0x78)

nan8(::Type{Float8}) = Float8(0x78)
nan8(::Type{Float8_4}) = Float8_4(0x7c)

const NaN8 = nan8(Float8)
const Inf8 = inf8(Float8)

const NaN8_4 = nan8(Float8_4)
const Inf8_4 = inf8(Float8_4)

typemin(::Type{T}) where {T<:AbstractFloat8} = -inf8(T)
typemax(::Type{T}) where {T<:AbstractFloat8} = inf8(T)

# smallest non-subnormal number, largest representable number
floatmin(::Type{Float8}) = Float8(0x10)
floatmin(::Type{Float8_4}) = Float8_4(0x08)
floatmax(::Type{Float8}) = Float8(0x6f)
floatmax(::Type{Float8_4}) = Float8_4(0x77)

# one and zero element
one(::Type{Float8}) = Float8(0x30)
one(::Type{Float8_4}) = Float8_4(0x38)
zero(::Type{T}) where {T<:AbstractFloat8} = Float8(0x00)

one(x::AbstractFloat8) = one(typeof(x))
zero(x::AbstractFloat8) = zero(typeof(x))

# is positive zero 0x00 or negative zero 0x80
iszero(x::AbstractFloat8) = reinterpret(UInt8, x) == 0x00 || reinterpret(UInt8,x) == 0x80
-(x::T) where {T<:AbstractFloat8} = reinterpret(T, reinterpret(UInt8, x) ⊻ 0x80)
Bool(x::AbstractFloat8) = iszero(x) ? false : isone(x) ? true : throw(InexactError(:Bool, Bool, x))

abs(x::T) where {T<:AbstractFloat8} = reinterpret(T, reinterpret(UInt8, x) & 0x7f)
isnan(x::T) where {T<:AbstractFloat8} = reinterpret(UInt8,x) & 0x7f > exponent_mask(T)
isfinite(x::T) where {T<:AbstractFloat8} = reinterpret(UInt8,x) & exponent_mask(T) != exponent_mask(T)

precision(::Type{Float8}) = 5
precision(::Type{Float8_4}) = 4

signbit(x::AbstractFloat8) = UInt8(x) > 0x7f

function sign(x::T) where {T<:AbstractFloat8}
    if isnan(x) || iszero(x)
        return x
    elseif signbit(x)
        return -one(T)
    else
        return one(T)
    end
end

first_sig_bit_mask(::Type{Float8}) = 0x00000008
first_sig_bit_mask(::Type{Float8_4}) = 0x00000004

sig_bit_shift(::Type{Float8}) = 19          # 23 significand bits for Float32 - 4 significand bits for Float8
sig_bit_shift(::Type{Float8_4}) = 20        # 23 significand bits for Float32 - 3 significand bits for Float8_4

bias_difference(::Type{Float8}) = 0x0000007c        # = 124, 127 for Float32 minus 3 for Float 8
bias_difference(::Type{Float8_4}) = 0x00000078      # = 120, 127 for Float32 minus 7 for Float 8_4

exp_bits_all_one(::Type{Float8}) = 0x00000007
exp_bits_all_one(::Type{Float8_4}) = 0x0000000f

round(x::T, r::RoundingMode{:ToZero}) where {T<:AbstractFloat8} = T(round(Float32(x), r))
round(x::T, r::RoundingMode{:Down}) where {T<:AbstractFloat8} = T(round(Float32(x), r))
round(x::T, r::RoundingMode{:Up}) where {T<:AbstractFloat8} = T(round(Float32(x), r))
round(x::T, r::RoundingMode{:Nearest}) where {T<:AbstractFloat8} = T(round(Float32(x), r))

function ==(x::AbstractFloat8, y::AbstractFloat8)
    if isnan(x) || isnan(y)     # Alternatively, For Float16: (ix|iy)&0x7fff > 0x7c00
        return false
    end
    if iszero(x) && iszero(y)   # For Float16: (ix|iy)&0x7fff == 0x0000
        return true
    end
    return reinterpret(UInt8,x) == reinterpret(UInt8,y)
end

for op in (:<, :<=, :isless)
    @eval ($op)(a::T, b::T) where {T<:AbstractFloat8} = ($op)(Float32(a), Float32(b))
end

for op in (:+, :-, :*, :/, :\, :^)
    @eval ($op)(a::Float8, b::Float8) = Float8(($op)(Float32(a), Float32(b)))
    @eval ($op)(a::Float8_4, b::Float8_4) = Float8_4(($op)(Float32(a), Float32(b)))
end

for func in (:sin,:cos,:tan,:cis,:sinpi,:cospi,:tanpi,:cispi,:sinh,:cosh,:tanh,
             :asin,:acos,:atan,:asinh,:acosh,:atanh,
             :exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:log1p,
             :sqrt,:cbrt,:lgamma)
    @eval begin
        $func(a::Float8) = Float8($func(Float32(a)))
        $func(a::Float8_4) = Float8_4($func(Float32(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        $func(a::Float8,b::Float8) = Float8($func(Float32(a),Float32(b)))
        $func(a::Float8_4,b::Float8_4) = Float8_4($func(Float32(a),Float32(b)))
    end
end

function Base.show(io::IO,x::Float8)
    if isnan(x)
        print(io,"NaN8")
    elseif isinf(x)
        if UInt8(x) > 0x80  # is negative?
            print(io,"-Inf8")
        else
            print(io,"Inf8")
        end
    else
        io2 = IOBuffer()
        print(io2,Float32(x))
        f = String(take!(io2))
        print(io,"Float8("*f*")")
    end
end

function Base.show(io::IO,x::Float8_4)
    if isnan(x)
        print(io,"NaN8_4")
    elseif isinf(x)
        if UInt8(x) > 0x80  # is negative?
            print(io,"-Inf8_4")
        else
            print(io,"Inf8_4")
        end
    else
        io2 = IOBuffer()
        print(io2,Float32(x))
        f = String(take!(io2))
        print(io,"Float8_4("*f*")")
    end
end

function nextfloat(x::T) where {T<:AbstractFloat8}
    if isnan(x) || x == inf8(T)
        return x
    elseif x == -zero(T)
        return T(0x01)
    elseif UInt8(x) < 0x80  # positive numbers
        return T(UInt8(x)+0x1)
    else                    # negative numbers
        return T(UInt8(x)-0x1)
    end
end

function prevfloat(x::T) where {T<:AbstractFloat8}
    if isnan(x) || x == -inf8(T)
        return x
    elseif x == zero(T)
        return T(0x81)
    elseif UInt8(x) < 0x80
        return T(UInt8(x)-0x1)
    else
        return T(UInt8(x)+0x1)
    end
end

Base.promote_rule(::Type{Float8},::Type{Float16}) = Float16
Base.promote_rule(::Type{Float8},::Type{Float32}) = Float32
Base.promote_rule(::Type{Float8},::Type{Float64}) = Float64
Base.promote_rule(::Type{Float8},::Type{<:Integer}) = Float8

Base.promote_rule(::Type{Float8_4},::Type{Float16}) = Float16
Base.promote_rule(::Type{Float8_4},::Type{Float32}) = Float32
Base.promote_rule(::Type{Float8_4},::Type{Float64}) = Float64
Base.promote_rule(::Type{Float8_4},::Type{<:Integer}) = Float8_4
