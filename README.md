[![CI](https://github.com/milankl/Float8s.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/milankl/Float8s.jl/actions/workflows/CI.yml)  

# Float8s.jl
Finally a number type that you can count with your fingers. Super Mario and Zelda would be proud.

Comes in two flavours: `Float8` has 3 exponent bits and 4 fraction bits, `Float8_4` has 4 exponent bits and 3 fraction bits.
Both rely on conversion to Float32 to perform any arithmetic operation, similar to `Float16`.

CAUTION: `Float8_4(::Float32)` currently contains a bug for subnormals.

# Example use

```julia
julia> using Float8s

julia> a = Float8(4)
Float8(4.0)

julia> b = Float8(3.14159)
Float8(3.125)

julia> a+b
Float8(7.0)

julia> sqrt(a)
Float8(2.0)

julia> a^2
Inf8
```
Most arithmetic operations are implemented. If you would like to have an additional feature, raise an [issue](https://github.com/milankl/Float8s.jl/issues).

# Installation

`Float8s.jl` is registered, just do
```julia
pkg> add Float8s
```

# Citation

This package was written for the following publication

> Klöwer M, PD Düben and TN Palmer, 2020. *Number formats, error mitigation and scope for 16-bit arithmetics in weather and climate modelling analyzed with a shallow water model*, __Journal of Advances in Modeling Earth Systems__, 12, e2020MS002246. doi: [10.1029/2020MS002246](https://doi.org/10.1029/2020MS002246)

If you use this package in your own research, please cite us.
