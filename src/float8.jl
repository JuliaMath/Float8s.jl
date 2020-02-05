primitive type Float8 <: AbstractFloat 8 end

# Float32 -> Float16 algorithm from:
#   "Fast Half Float Conversion" by Jeroen van der Zijp
#   ftp://ftp.fox-toolkit.org/pub/fasthalffloatconversion.pdf
#
# With adjustments for round-to-nearest, ties to even.
#
# let _basetable = Vector{UInt16}(undef, 512),
#     _shifttable = Vector{UInt8}(undef, 512)
#     for i = 0:255
#         e = i - 127
#         if e < -25  # Very small numbers map to zero
#             _basetable[i|0x000+1] = 0x0000
#             _basetable[i|0x100+1] = 0x8000
#             _shifttable[i|0x000+1] = 25
#             _shifttable[i|0x100+1] = 25
#         elseif e < -14  # Small numbers map to denorms
#             _basetable[i|0x000+1] = 0x0000
#             _basetable[i|0x100+1] = 0x8000
#             _shifttable[i|0x000+1] = -e-1
#             _shifttable[i|0x100+1] = -e-1
#         elseif e <= 15  # Normal numbers just lose precision
#             _basetable[i|0x000+1] = ((e+15)<<10)
#             _basetable[i|0x100+1] = ((e+15)<<10) | 0x8000
#             _shifttable[i|0x000+1] = 13
#             _shifttable[i|0x100+1] = 13
#         elseif e < 128  # Large numbers map to Infinity
#             _basetable[i|0x000+1] = 0x7C00
#             _basetable[i|0x100+1] = 0xFC00
#             _shifttable[i|0x000+1] = 24
#             _shifttable[i|0x100+1] = 24
#         else  # Infinity and NaN's stay Infinity and NaN's
#             _basetable[i|0x000+1] = 0x7C00
#             _basetable[i|0x100+1] = 0xFC00
#             _shifttable[i|0x000+1] = 13
#             _shifttable[i|0x100+1] = 13
#         end
#     end
#     global const shifttable = (_shifttable...,)
#     global const basetable = (_basetable...,)
# end
#
# function Float16(val::Float32)
#     f = reinterpret(UInt32, val)
#     if isnan(val)
#         t = 0x8000 ⊻ (0x8000 & ((f >> 0x10) % UInt16))
#         return reinterpret(Float16, t ⊻ ((f >> 0xd) % UInt16))
#     end
#     i = ((f & ~significand_mask(Float32)) >> significand_bits(Float32)) + 1
#     @inbounds sh = shifttable[i]
#     f &= significand_mask(Float32)
#     # If `val` is subnormal, the tables are set up to force the
#     # result to 0, so the significand has an implicit `1` in the
#     # cases we care about.
#     f |= significand_mask(Float32) + 0x1
#     @inbounds h = (basetable[i] + (f >> sh) & significand_mask(Float16)) % UInt16
#     # round
#     # NOTE: we maybe should ignore NaNs here, but the payload is
#     # getting truncated anyway so "rounding" it might not matter
#     nextbit = (f >> (sh-1)) & 1
#     if nextbit != 0 && (h & 0x7C00) != 0x7C00
#         # Round halfway to even or check lower bits
#         if h&1 == 1 || (f & ((1<<(sh-1))-1)) != 0
#             h += UInt16(1)
#         end
#     end
#     reinterpret(Float16, h)
# end
#
# function Float32(val::Float16)
#     local ival::UInt32 = reinterpret(UInt16, val)
#     local sign::UInt32 = (ival & 0x8000) >> 15
#     local exp::UInt32  = (ival & 0x7c00) >> 10
#     local sig::UInt32  = (ival & 0x3ff) >> 0
#     local ret::UInt32
#
#     if exp == 0
#         if sig == 0
#             sign = sign << 31
#             ret = sign | exp | sig
#         else
#             n_bit = 1
#             bit = 0x0200
#             while (bit & sig) == 0
#                 n_bit = n_bit + 1
#                 bit = bit >> 1
#             end
#             sign = sign << 31
#             exp = ((-14 - n_bit + 127) << 23) % UInt32
#             sig = ((sig & (~bit)) << n_bit) << (23 - 10)
#             ret = sign | exp | sig
#         end
#     elseif exp == 0x1f
#         if sig == 0  # Inf
#             if sign == 0
#                 ret = 0x7f800000
#             else
#                 ret = 0xff800000
#             end
#         else  # NaN
#             ret = 0x7fc00000 | (sign<<31) | (sig<<(23-10))
#         end
#     else
#         sign = sign << 31
#         exp  = ((exp - 15 + 127) << 23) % UInt32
#         sig  = sig << (23 - 10)
#         ret = sign | exp | sig
#     end
#     return reinterpret(Float32, ret)
# end

Bool(x::Float8) = x==0 ? false : x==1 ? true : throw(InexactError(:Bool, Bool, x))

round(x::Float8, r::RoundingMode{:ToZero}) = Float8(round(Float32(x), r))
round(x::Float8, r::RoundingMode{:Down}) = Float8(round(Float32(x), r))
round(x::Float8, r::RoundingMode{:Up}) = Float8(round(Float32(x), r))
round(x::Float8, r::RoundingMode{:Nearest}) = Float8(round(Float32(x), r))

-(x::Float8) = reinterpret(Float8, reinterpret(UInt8, x) ⊻ 0x80)

function ==(x::Float8, y::Float8)
    if isnan(x) || isnan(y) # For Float16: (ix|iy)&0x7fff > 0x7c00
        return false
    end
    if iszero(x) && iszero(y) # For Float16: (ix|iy)&0x7fff == 0x0000
        return true
    end
    ix = reinterpret(UInt8,x)
    iy = reinterpret(UInt8,y)
    return ix == iy
end

for op in (:<, :<=, :isless)
    @eval ($op)(a::Float8, b::Float8) = ($op)(Float32(a), Float32(b))
end

abs(x::Float8) = reinterpret(Float8, reinterpret(UInt8, x) & 0x7f)
isnan(x::Float8) = reinterpret(UInt8,x)&0x7f > exponent_mask(Float8)
isfinite(x::Float8) = reinterpret(UInt8,x)&exponent_mas(Float8) != exponent_mask(Float8)

precision(::Type{Float8}) = 4

@eval begin
    typemin(::Type{Float16}) = $(bitcast(Float16, 0xfc00))
    typemax(::Type{Float16}) = $(Inf16)
    typemin(x::T) where {T<:Real} = typemin(T)
    typemax(x::T) where {T<:Real} = typemax(T)

    floatmin(::Type{Float16}) = $(bitcast(Float16, 0x0400))
    floatmax(::Type{Float16}) = $(bitcast(Float16, 0x7bff))

    eps(x::AbstractFloat) = isfinite(x) ? abs(x) >= floatmin(x) ? ldexp(eps(typeof(x)), exponent(x)) : nextfloat(zero(x)) : oftype(x, NaN)
    eps(::Type{Float16}) = $(bitcast(Float16, 0x1400))
end

sign_mask(::Type{Float8}) = 0x80
exponent_mask(::Type{Float8}) = 0x78        # 0x78 for 4 exp bits, 0x70 for 3 exp bits
# exponent_one(::Type{Float16}) =     0x3c00
# exponent_half(::Type{Float16}) =    0x3800
significand_mask(::Type{Float8}) = 0x07     # 0x07 for 4 exp bits, 0x0f for 3 exp bits

for T in (Float16, Float32, Float64)
    @eval significand_bits(::Type{$T}) = $(trailing_ones(significand_mask(T)))
    @eval exponent_bits(::Type{$T}) = $(sizeof(T)*8 - significand_bits(T) - 1)
    @eval exponent_bias(::Type{$T}) = $(Int(exponent_one(T) >> significand_bits(T)))
    # maximum float exponent
    @eval exponent_max(::Type{$T}) = $(Int(exponent_mask(T) >> significand_bits(T)) - exponent_bias(T))
    # maximum float exponent without bias
    @eval exponent_raw_max(::Type{$T}) = $(Int(exponent_mask(T) >> significand_bits(T)))
end

uinttype(::Type{Float8}) = UInt8
iszero(x::Float8) = reinterpret(UInt8, x) & ~sign_mask(Float8) == 0x00
Float8(x::UInt8) = reinterpret(Float8,x)
bitstring(x::Float8) = bitstring(reinterpret(UInt8,x))
