# written by Jeffrey Sarnoff, Feb 2020.
# the constants
# ---------------

#=
   One table is split into subsections of 16 entries each.
   This keeps the scan time minimal, even after accounting
   for the conditionals that select the proper subsection.

   These are Float8 values offset by 1/2 way to the next value,
   this lets `findfirst` return an appropriately rounded value.

   The `F8offsetN` tuples are used with normal values,
   values that are finite and are not subnormal. Values
   that round to zero are handled before these are used.
=#

const F8offset1 = (Float32[
   0.2578125, 0.2734375, 0.2890625, 0.3046875, 0.3203125, 0.3359375,
   0.3515625, 0.3671875, 0.3828125, 0.3984375, 0.4140625, 0.4296875,
   0.4453125, 0.4609375, 0.4765625, 0.4921875]...,)

const F8offset2 = (Float32[
    0.515625, 0.546875, 0.578125, 0.609375, 0.640625, 0.671875,
    0.703125, 0.734375, 0.765625, 0.796875, 0.828125, 0.859375,
    0.890625, 0.921875, 0.953125, 0.984375]...,);

const F8offset3 = (Float32[
    1.03125, 1.09375, 1.15625, 1.21875, 1.28125, 1.34375, 1.40625,
    1.46875, 1.53125, 1.59375, 1.65625, 1.71875, 1.78125, 1.84375,
    1.90625, 1.96875]...,);

const F8offset4 = (Float32[
    2.0625, 2.1875, 2.3125, 2.4375, 2.5625, 2.6875, 2.8125,
    2.9375, 3.0625, 3.1875, 3.3125, 3.4375, 3.5625, 3.6875,
    3.8125, 3.9375]...,);

const F8offset5 = (Float32[
    4.125, 4.375, 4.625, 4.875, 5.125, 5.375, 5.625, 5.875, 6.125,
    6.375,  6.625, 6.875, 7.125, 7.375, 7.625, 7.875]...,);

const F8offset6 = (Float32[
    8.25, 8.75, 9.25, 9.75, 10.25, 10.75, 11.25, 11.75, 12.25, 12.75,
    13.25, 13.75, 14.25, 14.75, 15.25, 15.75]...,);
#=
     There is one table used with subnormal values.
      It is derived from the actual values of each
      subnormal quantity, shifted up halfway to the
      next subnormal.  This lets scanning also round.
      An initial (anchor) value is prepended, that value
      is half of the smallest subnormal.

     A corresponding table of UInt8 values also is used.
=#

const F8offset_subnormal = (
    0.0078125f0, 0.0234375f0, 0.0390625f0, 0.0546875f0, 0.0703125f0,
    0.0859375f0, 0.1015625f0, 0.1171875f0, 0.1328125f0, 0.1484375f0,
    0.1640625f0, 0.1796825f0, 0.1953125f0, 0.2109375f0, 0.2265625f0,
    0.2421875f0)

const U8subnormal = (collect(UInt8.(0:15))...,)

# some named constants to clarify the source text

const roundsto_floatmax8 = 15.25f0
const roundsto_zero8 = 0.0078125f0
const roundsto_subnormal = 0.2421875f0
const floatmaxplus8 = 15.75f0 # floatmax(Float8) + floatmin(Float8)

const UNaN8 = 0x78
const UInf8 = 0x70
const UFloatmax8 = 0x6f
const UFloatmin8 = 0x10
const UZero8 = 0x00

#  the functions
# ----------------

function Float8(x::Float32)
    # s, absx = signbit(x), abs(x)
    ui = toUInt8(x)
    return reinterpret(Float8, ui)
end

function toUInt8(x::Float32)
    s, absx = signbit(x), abs(x)
    isnan(absx) && return s ? UNaN8|0x80 : UNaN8
    if absx >= roundsto_floatmax8
        if absx > floatmaxplus8
            return s ? UInf8|0x80 : UInf8
        else
            return s ? UFloatmax8|0x80 : UFloatmax8
        end
    end
    if absx < roundsto_zero8
        return s ? UZero8|0x80 : UZero8
    elseif absx < roundsto_subnormal
        return subnormal8(s, absx)
    end
    absx = min(15.5f0, max(0.25f0, absx))
    return normal8(s, absx)
end

@inline function subnormal8(s::Core.Bool, absx::Float32)
    idx = findfirst(a->absx <= a, F8offset_subnormal)
    return s ? U8subnormal[idx] | 0x80 : U8subnormal[idx]
end

function normal8(s::Core.Bool, absx::Float32)
   if absx <= 1.96875f0
     if absx <= 0.4921875f0
          idx = UInt8(15+firstof16lte(absx, F8offset1))
          return s ? idx|0x80 : idx
     elseif absx <= 0.984375f0
          idx = UInt8(15+16+firstof16lte(absx, F8offset2))
          return s ? idx|0x80 : idx
     else
         idx = UInt8(15+32+firstof16lte(absx, F8offset3))
         return s ? idx|0x80 : idx
     end
   else
     if absx <= 3.9375f0
         idx = UInt8(15+32+16+firstof16lte(absx, F8offset4))
         return s ? idx|0x80 : idx
     elseif absx <= 7.875f0
         idx = UInt8(15+64+firstof16lte(absx, F8offset5))
         return s ? idx|0x80 : idx
     else
         idx = UInt8(15+64+16+firstof16lte(absx, F8offset6))
         return s ? idx|0x80 : idx
     end
   end
end

function firstof16lte(needle, haystack)
    for idx = 1:16
        if needle <= haystack[idx]
            return idx
        end
    end
    error("should not be reached")
end

# """Old version, slower."""
# function normal8(s::Bool, absx::Float32)
#    if absx <= 0.4921875f0
#         idx = UInt8(15+findfirst(a->absx <= a, F8offset1))
#         return s ? idx|0x80 : idx
#    elseif absx <= 0.984375f0
#         idx = UInt8(15+16+findfirst(a->absx <= a, F8offset2))
#         return s ? idx|0x80 : idx
#    elseif absx <= 1.96875f0
#        idx = UInt8(15+32+findfirst(a->absx <= a, F8offset3))
#        return s ? idx|0x80 : idx
#    elseif absx <= 3.9375f0
#        idx = UInt8(15+32+16+findfirst(a->absx <= a, F8offset4))
#        return s ? idx|0x80 : idx
#    elseif absx <= 7.875f0
#        idx = UInt8(15+64+findfirst(a->absx <= a, F8offset5))
#        return s ? idx|0x80 : idx
#    elseif absx <= 15.75f0
#        idx = UInt8(15+64+16+findfirst(a->absx <= a, F8offset6))
#        return s ? idx|0x80 : idx
#    else
#        throw(DomainError(absx,"not normal for Float8"))
#    end
# end
