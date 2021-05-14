# Blue Noise for Julia

The `BlueNoise` package provides several pregenerated sources of noise. It can
be used as follows:
```julia
using BlueNoise
x = 123
y = 456
println(blue_noise_2d1v(x, y))
```
Coordinates are integers and will automatically be wrapped to be in the domain
of the data. The algorithm used ensures that the noise can be tiled in this
way. The raw data can also be accessed like this:
```julia
using BlueNoise
using Plots
heatmap(BlueNoise.PREGENERATED_2D4V[:, :, 1])
```
Multiple values can be retrieved for a single coordinate, which is useful in
cases where multiple parameters need to be seeded:
```julia
using BlueNoise
(Δx, Δy) = blue_noise_2d2v(x, y)
```

The `BlueNoiseGeneration` package was used to generate the files included in
the `BlueNoise` package.
