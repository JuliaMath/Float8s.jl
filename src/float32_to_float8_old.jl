# Float32 -> Float8 algorithm in analogy to
#
# Float32 -> Float16 algorithm from:
#   "Fast Half Float Conversion" by Jeroen van der Zijp
#   ftp://ftp.fox-toolkit.org/pub/fasthalffloatconversion.pdf
#
# With adjustments for round-to-nearest, ties to even.

function create_base_shifttable(::Type{T}) where {T<:AbstractFloat8}

    basetable = Vector{UInt8}(undef, 512)
    shifttable = Vector{UInt8}(undef, 512)

    if T == Float8
        # elements derive from
        # [1]   2^-6 = Float8(0x01) the smallest representable number (subnormal)
        # [2]   2^-2 = Float8(0x10) the first non-subnormal number
        # [3]   2^4 = 16 > floatmax(Float8) is the smallest power of two that is larger than floatmax(Float8)

        e_limits = [-6,-2,4]

        # shift a 0x1 in the exponent bits created by "significand_mask(Float32) + 0x1"
        # to the first significand bit
        # e_shift_subnorm is 17 for Float8
        e_shift_subnorm = n_significant_bits(Float32)-(n_significant_bits(Float8)-1)+e_limits[2]-1
    elseif T == Float8_4

        # see above
        e_limits = [-9,-6,8]

        # shift a 0x1 in the exponent bits created by "significand_mask(Float32) + 0x1"
        # to the first significand bit
        # e_shift_subnorm is 14 for Float8_4
        e_shift_subnorm = n_significant_bits(Float32)-(n_significant_bits(Float8_4)-1)+e_limits[2]-1
    end

    for i = 0:255                               # all possible exponents for Float32
        e = i - 127                             # subtract Float32 bias
        if e < e_limits[1]                      # Very small numbers map to +- zero
            basetable[i|0x000+1] = zero(T)
            basetable[i|0x100+1] = -zero(T)
            shifttable[i|0x000+1] = n_significant_bits(T)+1
            shifttable[i|0x100+1] = n_significant_bits(T)+1
        elseif e < e_limits[2]                  # Small numbers map to denorms
            basetable[i|0x000+1] = zero(T)
            basetable[i|0x100+1] = -zero(T)
            shifttable[i|0x000+1] = -e+e_shift_subnorm
            shifttable[i|0x100+1] = -e+e_shift_subnorm
        elseif e < e_limits[3]                  # Normal numbers just lose precision
            basetable[i|0x000+1] = ((e+bias(T)) << n_significant_bits(T))
            basetable[i|0x100+1] = ((e+bias(T)) << n_significant_bits(T)) | sign_mask(T)
            shifttable[i|0x000+1] = n_significant_bits(Float32)-n_significant_bits(T)
            shifttable[i|0x100+1] = n_significant_bits(Float32)-n_significant_bits(T)
        elseif e < 128                          # Large numbers map to Infinity
            basetable[i|0x000+1] = inf8(T)
            basetable[i|0x100+1] = -inf8(T)
            shifttable[i|0x000+1] = n_significant_bits(T)+1
            shifttable[i|0x100+1] = n_significant_bits(T)+1
        else                                    # Infinity and NaN's stay Infinity and NaN's
            basetable[i|0x000+1] = inf8(T)
            basetable[i|0x100+1] = -inf8(T)
            shifttable[i|0x000+1] = n_significant_bits(Float32)-n_significant_bits(T)
            shifttable[i|0x100+1] = n_significant_bits(Float32)-n_significant_bits(T)
        end
    end

    return basetable, shifttable
end

const basetable8, shifttable8 = create_base_shifttable(Float8)
const basetable8_4, shifttable8_4 = create_base_shifttable(Float8_4)

# function Float8(val::Float32)
#
#     f = reinterpret(UInt32, val)
#
#     if isnan(val)       #TODO retain the significant bits for NaN?
#         return nan8(Float8)
#     end
#
#     # exponent as Int64
#     i = f >> n_significant_bits(Float32) + 1
#     @inbounds sh = shifttable8[i]
#     f &= significand_mask(Float32)
#
#     # If `val` is subnormal, the tables are set up to force the
#     # result to 0, so the significand has an implicit `1` in the
#     # cases we care about.
#
#     f |= significand_mask(Float32) + 0x1
#     @inbounds h = (basetable8[i] + (f >> sh) & significand_mask(Float8)) % UInt8
#
#     # rounding
#     nextbit = (f >> (sh-1)) & 1
#     if nextbit != 0 && (h & exponent_mask(Float8)) != exponent_mask(Float8)
#         # Round halfway to even or check lower bits
#         if h&1 == 1 || (f & ((1<<(sh-1))-1)) != 0
#             h += one(UInt8)
#         end
#     end
#     return reinterpret(Float8, h)
# end

function Float8_4(val::Float32)

    f = reinterpret(UInt32, val)

    if isnan(val)       #TODO retain the significant bits for NaN?
        return nan8(Float8_4)
    end

    # exponent as Int64
    i = f >> n_significant_bits(Float32) + 1
    @inbounds sh = shifttable8_4[i]
    f &= significand_mask(Float32)

    # If `val` is subnormal, the tables are set up to force the
    # result to 0, so the significand has an implicit `1` in the
    # cases we care about.

    f |= significand_mask(Float32) + 0x1
    @inbounds h = (basetable8_4[i] + (f >> sh) & significand_mask(Float8_4)) % UInt8

    # rounding
    nextbit = (f >> (sh-1)) & 1
    if nextbit != 0 && (h & exponent_mask(Float8_4)) != exponent_mask(Float8_4)
        # Round halfway to even or check lower bits
        if h&1 == 1 || (f & ((1<<(sh-1))-1)) != 0
            h += one(UInt8)
        end
    end
    return reinterpret(Float8_4, h)
end
