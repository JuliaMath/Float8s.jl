[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://img.shields.io/badge/repo_status-active-brightgreen?style=flat-square)](https://www.repostatus.org/#active)
[![Travis](https://img.shields.io/travis/com/milankl/Float8s.jl?label=Linux%20%26%20osx&logo=travis&style=flat-square)](https://travis-ci.com/milankl/Float8s.jl)
[![AppVeyor](https://img.shields.io/appveyor/ci/milankl/Float8s-jl?label=Windows&logo=appveyor&logoColor=white&style=flat-square)](https://ci.appveyor.com/project/milankl/Float8s-jl)
[![Cirrus CI](https://img.shields.io/cirrus/github/milankl/Float8s.jl?label=FreeBSD&logo=cirrus-ci&logoColor=white&style=flat-square)](https://cirrus-ci.com/github/milankl/Float8s.jl)

# Float8s.jl
Finally a number type that you can count with your fingers. Super Mario and Zelda would be proud.

Comes in two flavours: `Float8` has 3 exponent bits and 4 fraction bits, `Float8_4` has 4 exponent bits and 3 fraction bits.
Both rely on conversion to Float32 to perform any arithmetic operation.

# Benchmarking
```julia
julia> using BenchmarkTools

julia> A = Float8.(randn(300,300));

julia> @btime Float32.($A);
  413.303 μs (2 allocations: 351.64 KiB)

julia> 413.303/300^2*1000
4.592255555555555
```
Conversions from Float8 to Float32 take about 4.5ns (table-driven), conversions in the other direction are about 2x slower (lookup tables could probably improve the performance though). 
```julia
julia> B = randn(Float32,300,300);

julia> @btime Float8.($B);
  922.728 μs (2 allocations: 88.02 KiB)
 ```
 
