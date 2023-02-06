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
(v1.3) pkg> add Float8s
```

# Benchmarking
Conversions from `Float8` (same for `Float8_4`) to `Float32` take about 1.5ns, about 2x faster than for conversions from `Float16` thanks to table lookups.
```julia
julia> using Float8s, BenchmarkTools
julia> A = Float8.(randn(300,300));
julia> B = Float16.(randn(300,300));
julia> @btime Float32.($A);
  133.060 μs (2 allocations: 351.64 KiB)
julia> @btime Float32.($B);
  232.701 μs (2 allocations: 351.64 KiB)
```
 Conversions in the other direction are about 6-7x slower and slightly slower than for `Float16`. 
```julia
julia> C = Float32.(randn(300,300));
julia> @btime Float16.($C);
  672.419 μs (2 allocations: 175.89 KiB)
julia> @btime Float8.($C);
  873.585 μs (2 allocations: 88.02 KiB) 
 ```
 
