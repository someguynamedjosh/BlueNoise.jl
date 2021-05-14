module BlueNoiseGeneration

using FFTW
using Plots
using Random
using StaticArrays

struct Parameters
    starting_density::Float64
    σ::Float64
    neighborhood_size::Int
end

Parameters() = Parameters(1 / 10, 2.0, 128)

function voidandcluster_energy_kernel(
    parameters::Parameters, dims::NTuple{D,Int}
)::Array{Float64,D} where {D}
    result = zeros(Float64, dims)
    for other_coordinate in CartesianIndices(dims)
        axis_distances = abs.(Tuple(other_coordinate) .- 1)
        # "Toroidal distance", i.e. pick which is closer between going to the
        # point the normal way or going to the point by wrapping around the
        # other direction:
        #  x-----x    distance: 6
        # -x     x-   distance: 3
        # 123456789
        axis_distances = min.(axis_distances, dims .- axis_distances)
        distance_squared = sum(axis_distances.^2)
        # Gaussian filter.
        result[other_coordinate] = exp(distance_squared / (-2 * parameters.σ^2))
    end
    result
end

const REDUCE_THRESHOLD = 1e-5

# struct ReducedKernel{D,T}
#     taps::SVector{T,Tuple{CartesianIndex{D},Float64}}
# end

struct ReducedKernel{D,T}
    taps::Vector{Tuple{CartesianIndex{D},Float64}}
end

function reduce_kernel(full::Array{Float64,D}) where D
    taps::Vector{Tuple{CartesianIndex{D},Float64}} = []
    for index in CartesianIndices(full)
        value_here = full[index]
        if value_here >= REDUCE_THRESHOLD
            push!(taps, (CartesianIndex(Tuple(index) .- 1), value_here))
        end
    end
    reduction = prod(size(full)) ÷ length(taps)
    println("Reduced kernel size x$reduction (now $(length(taps)) taps)")
    # num_taps = length(taps)
    # staps = SVector{num_taps,Tuple{CartesianIndex{D},Float64}}(taps)
    # ReducedKernel(staps)
    ReducedKernel{D,0}(taps)
end

function apply_kernel!(
    target::Array{Float64,D}, 
    kernel::ReducedKernel{D,T}, 
    offset::CartesianIndex{D}, 
    ::Val{A}
) where {D,T,A}
    target_size = size(target)
    for (tap_offset::CartesianIndex{D}, tap_value::Float64) in kernel.taps
        target_pos = mod1.(Tuple(tap_offset) .+ Tuple(offset), target_size)
        target_pos = CartesianIndex(target_pos)
        if A
            target[target_pos] += tap_value
        else
            target[target_pos] -= tap_value
        end
    end
end

add_kernel!(target::Array{Float64,D}, kernel::ReducedKernel{D}, offset::CartesianIndex{D}) where D = 
    apply_kernel!(target, kernel, offset, Val(true))

sub_kernel!(target::Array{Float64,D}, kernel::ReducedKernel{D}, offset::CartesianIndex{D}) where D = 
    apply_kernel!(target, kernel, offset, Val(false))

function generate(parameters::Parameters, size::NTuple{D,Int}) where {D}
    binary_pattern = Array{Bool,D}(undef, size...)
    energy = zeros(Float64, size)
    kernel = reduce_kernel(voidandcluster_energy_kernel(parameters, size))
    indices = CartesianIndices(binary_pattern)
    ns = parameters.neighborhood_size ÷ 2^D
    println("Neighborhood size is $ns^$D")
    neighborhood_origins = @view indices[ntuple(x -> 1:ns:size[x], ndims(binary_pattern))...]
    neighborhood_element_offsets = CartesianIndices(ntuple(x -> ns, ndims(binary_pattern)))

    function find_tightest_cluster()::Int
        raw_index = 1
        highest_value = energy[raw_index]
        for candidate in 2:length(energy)
            if binary_pattern[candidate] == false
                continue
            end
            value_here = energy[candidate]
            if value_here > highest_value
                highest_value = value_here
                raw_index = candidate
            end
        end
        raw_index
    end

    function find_largest_void()::Int
        raw_index = 1
        lowest_value = energy[raw_index]
        for candidate in 2:length(energy)
            if binary_pattern[candidate] == true
                continue
            end
            value_here = energy[candidate]
            if value_here < lowest_value
                lowest_value = value_here
                raw_index = candidate
            end
        end
        raw_index
    end

    function find_largest_void_in_neighborhood(neighborhood_origin::CartesianIndex{D})::CartesianIndex{D}
        pos = neighborhood_origin
        lowest_value = energy[pos]
        for offset in neighborhood_element_offsets
            candidate = CartesianIndex(Tuple(neighborhood_origin + offset) .- 1)
            if binary_pattern[candidate] == true
                continue
            end
            value_here = energy[candidate]
            if value_here < lowest_value
                lowest_value = value_here
                pos = candidate
            end
        end
        pos
    end

    # Set all pixels to be zero
    for index in indices
        binary_pattern[index] = false
    end
    # Set up to (total_pixels * ONES_DENSITY) pixels to be ones.
    for _ in 1:floor(Int64, prod(size) * parameters.starting_density^length(size))
        index = rand(indices)
        if binary_pattern[index] == true
            # Don't add energy to the same pixel twice.
            continue
        end
        binary_pattern[index] = true
        add_kernel!(energy, kernel, indices[index])
    end

    # Distribute them more regularly.
    iteration_limit = prod(size)
    while iteration_limit > 0
        tightest_cluster = find_tightest_cluster()
        binary_pattern[tightest_cluster] = false
        sub_kernel!(energy, kernel, indices[tightest_cluster])
        largest_void = find_largest_void()
        if largest_void === tightest_cluster
            # Restore the '1' we just removed.
            binary_pattern[tightest_cluster] = true
            add_kernel!(energy, kernel, indices[tightest_cluster])
            break
        end
        # @assert binary_pattern[largest_void] == false
        binary_pattern[largest_void] = true
        add_kernel!(energy, kernel, indices[largest_void])
        iteration_limit -= 1
    end
    if iteration_limit == 0
        throw(ErrorException("Iteration limit exceeded."))
    end

    initial_binary_pattern = copy(binary_pattern)
    ones_in_ibp = sum(Int64, initial_binary_pattern)
    result = zeros(Int64, size...)

    # Phase I from paper, write a value to the result for each 1 in the IBP.
    rank = ones_in_ibp - 1
    while rank >= 0
        tightest_cluster = find_tightest_cluster()
        # @assert binary_pattern[tightest_cluster] == true
        binary_pattern[tightest_cluster] = false
        sub_kernel!(energy, kernel, indices[tightest_cluster])
        result[tightest_cluster] = rank
        rank -= 1
    end

    # Phase II and III, add pixels to largest voids. The paper splits this into
    # two steps that are actually mathematically equivalent :P oh well.
    binary_pattern .= initial_binary_pattern
    # Assert all the energies are basically zero.
    # @assert prod(abs.(energy .- zeros(size)) .< 1f-4)
    rank = ones_in_ibp
    ## Set up energy to be correct.
    @inbounds for raw_index in eachindex(binary_pattern)
        if binary_pattern[raw_index] != true
            continue
        end
        index = indices[raw_index]
        add_kernel!(energy, kernel, index)
    end
    neighborhood_order = shuffle(neighborhood_origins)
    neighborhood_index = 1
    while rank < Int64(prod(size))
        neighborhood = neighborhood_order[neighborhood_index]
        largest_void = find_largest_void_in_neighborhood(neighborhood)
        # @assert binary_pattern[largest_void] == false
        binary_pattern[largest_void] = true
        add_kernel!(energy, kernel, indices[largest_void])
        result[largest_void] = rank
        rank += 1
        neighborhood_index += 1
        if neighborhood_index > length(neighborhood_order)
            neighborhood_index = 1
        end
    end

    result
end

function serialize(data::Array{Int64,D})::String where D
    buffer = Array{UInt8}(undef, 3 + length(data) * 16)
    buffer[1] = '('
    buffer[2] = 'b'
    buffer[3] = '"'
    pos = 4
    for element in data
        for digit in 1:16
            buffer[pos + 16 - digit] = b"0123456789ABCDEF"[(element >> (digit * 4 - 4)) & 0xF + 1]
        end
        pos += 16
    end
    String(buffer) * "\", $(size(data)))"
end

function make_noise(dim::Val{D}, size::Val{S}, channels::Int) where {D,S}
    dims = ntuple(x -> S, dim)
    data = Array{Int64,D + 1}(undef, (dims..., channels))
    total_time = 0.0
    for channel in 1:channels
        index = (ntuple(x -> :, dim)..., channel)
        start = time()
        data[index...] .= generate(Parameters(), dims)
        total_time += time() - start
    end
    println("Generated in $(ceil(Int64, total_time)) seconds")
    serialized = serialize(data)
    open(
        f -> write(f, serialized), 
        "BlueNoise/src/generated_$(D)d$(channels)v_res$(S).jl",
        "w"
    )
end

function frequency_plot(data::Array{Float64,D}) where {D}
    heatmap(abs.(FFTW.dct(data .- 0.5)), aspect_ratio=1, clim=(0.0, 1.0))
end

export Parameters, generate, frequency_plot, make_noise

# begin 
#     params = Parameters()
#     d1 = generate(params, (64, 64))
#     p1 = frequency_plot(d1)
#     params = Parameters(1//30, 1.5)
#     d2 = generate(params, (64, 64))
#     p2 = frequency_plot(d2)
#     plot(p1, p2, heatmap(d1), heatmap(d2))
# end

end # module
