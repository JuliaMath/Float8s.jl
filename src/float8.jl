abstract type AbstractFloat8 <: AbstractFloat end
primitive type Float8 <: AbstractFloat8 8 end        # standard 3 exp version
primitive type Float8_4 <: AbstractFloat8 8 end      # version with 4 exp bits

Float8(x::UInt8) = reinterpret(Float8,x)
Float8_4(x::UInt8) = reinterpret(Float8_4,x)
bitstring(x::AbstractFloat8) = bitstring(reinterpret(UInt8,x))

# masks, UInt8s with 1s for the respective parts
sign_mask(::Type{T}) where {T<:AbstractFloat8} = 0x80
exponent_mask(::Type{Float8}) = 0x70
exponent_mask(::Type{Float8_4}) = 0x78
significand_mask(::Type{Float8}) = 0x0f
significand_mask(::Type{Float8_4}) = 0x07

# number of exp/sig bits
n_exponent_bits(::Type{Float8}) = 3
n_exponent_bits(::Type{Float8_4}) = 4
n_significant_bits(::Type{Float8}) = 4
n_significant_bits(::Type{Float8_4}) = 3

eps(::Type{Float8}) = Float8(0x02)
eps(::Type{Float8_4}) = Float8_4(0x20)

# define inifinities and nan
inf8(::Type{Float8}) = Float8(0x70)
inf8(::Type{Float8_4}) = Float8_4(0x78)

nan8(::Type{Float8}) = Float8(0x78)
nan8(::Type{Float8_4}) = Float8_4(0x7c)

const NaN8 = nan8(Float8)
const Inf8 = inf8(Float8)

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

first_sig_bit_mask(::Type{Float8}) = 0x00000008
first_sig_bit_mask(::Type{Float8_4}) = 0x00000004

sig_bit_shift(::Type{Float8}) = 19          # 23 significand bits for Float32 - 4 significand bits for Float8
sig_bit_shift(::Type{Float8_4}) = 20        # 23 significand bits for Float32 - 3 significand bits for Float8_4

bias_difference(::Type{Float8}) = 0x0000007c    # = 124, 127 for Float32 minus 3 for Float 8
bias_difference(::Type{Float8_4}) = 0x00000078    # = 120, 127 for Float32 minus 7 for Float 8_4

exp_bits_all_one(::Type{Float8}) = 0x00000007
exp_bits_all_one(::Type{Float8_4}) = 0x0000000f

function Float32(val::T) where {T<:AbstractFloat8}

    ival = reinterpret(UInt8, val)

    # seperate into sign, exponent, significand
    sign = UInt32((ival & sign_mask(T)) >> 7)
    exp  = UInt32((ival & exponent_mask(T)) >> n_significant_bits(T))
    sig = UInt32(ival & significand_mask(T))

    if exp == zero(UInt32)
        if sig == zero(UInt32)          # +-0 case
            return reinterpret(Float32,sign << 31)
        else                            # subnormals
            n_bit = 1
            # first significand bit set to one, else zero, to check for size of subnormal
            bit = first_sig_bit_mask(T)
            while (bit & sig) == 0
                n_bit = n_bit + 1
                bit = bit >> 1
            end
            sign = sign << 31

            # bias = 2^(n_exp-1) - 1, i.e. 127 for Float32, 15 for Float16, 3 for Float8, 7 for Float8_4
            # difference in bias + 1 has to be added, e.g. 127-3 = 124 = 0x0000007c

            exp = ((bias_difference(T)+1 - n_bit) << 23) % UInt32
            sig = ((sig & (~bit)) << n_bit) << sig_bit_shift(T)
            ret = sign | exp | sig
            reinterpret(Float32,ret)
        end
    elseif exp == exp_bits_all_one(T)       # Inf/NaN case
        if sig == zero(UInt32)              # Infinity
            if sign == zero(UInt32)
                return Inf32
            else
                return -Inf32
            end
        else                # NaN, preserve sign and significand (first sig bit always 1)
            # NaN32 == reinterpret(Flaot32,0x7fc00000)
            ret = 0x7fc00000 | (sign<<31) | (sig<<sig_bit_shift(T))
            reinterpret(Float32,ret)
        end
    else
        sign = sign << 31

        # bias = 2^(n_exp-1) - 1, i.e. 127 for Float32, 15 for Float16, 3 for Float8, 7 for Float8_4
        # difference in bias has to be added, e.g. 127-3 = 124 = 0x0000007c

        exp  = (exp + bias_difference(T)) << 23
        sig  = sig << sig_bit_shift(T)
        ret = sign | exp | sig
        return reinterpret(Float32, ret)
    end
end

sign_mask(::Type{Float32}) = 0x80000000
exponent_mask(::Type{Float32}) = 0x7fc00000     # reinterpret(UInt32,Float32)
significand_mask(::Type{Float32}) = 0x803fffff   # ~reinterpret(UInt32,-NaN32)
n_exponent_bits(::Type{Float32}) = 8
n_significant_bits(::Type{Float32}) = 23

function Float8(val::Float32)
    local ival::UInt32 = reinterpret(UInt32, val)

    # seperate into sign, exponent, significand
    local sign::UInt32 = (ival & sign_mask(Float32)) >> 31
    local exp::UInt32  = (ival & exponent_mask(Float32)) >> n_significant_bits(Foat32)
    local sig::UInt32  = (ival & significand_mask(Float32))
    local ret::UInt8   # return value

    if exp == zero(UInt32)
        if sig == zero(UInt32)          # +-0 case
            ret = sign << 7
            return reinterpret(Float8,ret)
        else                            # subnormals,map to Inf8, -Inf8
            if sign == zero(UInt32)
                return inf(Float8)
            else
                return -inf(Float8)
            end
        end
    elseif exp == exponent_mask(Float32)        # all exponent bits == 1, Inf/NaN case
        if sig == zero(UInt32)                  # Infinity
            if sign == zero(UInt32)
                return inf8(Float8)
            else
                return -inf8(Float8)
            end
        else                                    # NaN
            return nan8(Float8)
        end
    else
        sign = sign << 31

        # bias = 2^(n_exp-1) - 1, i.e. 127 for Float32, 15 for Float16, 3 for Float8, 7 for Float8_4
        # difference in bias has to be added, e.g. 127-3 = 124 = 0x0000007c

        exp  = (exp + bias_difference(T)) << 23
        sig  = sig << sig_bit_shift(T)
        ret = sign | exp | sig
        return reinterpret(Float32, ret)
    end
end

round(x::T, r::RoundingMode{:ToZero}) where {T<:AbstractFloat8} = T(round(Float32(x), r))
round(x::T, r::RoundingMode{:Down}) where {T<:AbstractFloat8} = T(round(Float32(x), r))
round(x::T, r::RoundingMode{:Up}) where {T<:AbstractFloat8} = T(round(Float32(x), r))
round(x::T, r::RoundingMode{:Nearest}) where {T<:AbstractFloat8} = T(round(Float32(x), r))

function ==(x::AbstractFloat8, y::AbstractFloat8)
    if isnan(x) || isnan(y) # For Float16: (ix|iy)&0x7fff > 0x7c00
        return false
    end
    if iszero(x) && iszero(y) # For Float16: (ix|iy)&0x7fff == 0x0000
        return true
    end
    return x == y
end

for op in (:<, :<=, :isless)
    @eval ($op)(a::T, b::T) where {T<:AbstractFloat8} = ($op)(Float32(a), Float32(b))
end
