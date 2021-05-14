module BlueNoise

function _parse_generated_data(
    (raw_data, dimensions)::Tuple{Base.CodeUnits{UInt8},NTuple{D,Int}}
)::Array{Float64,D} where {D}
    result = Array{Float64,D}(undef, dimensions)
    indices = prod(dimensions)
    digit_values = Dict(
        b"0"[1] => 0, 
        b"1"[1] => 1,
        b"2"[1] => 2,
        b"3"[1] => 3,
        b"4"[1] => 4,
        b"5"[1] => 5,
        b"6"[1] => 6,
        b"7"[1] => 7,
        b"8"[1] => 8,
        b"9"[1] => 9,
        b"A"[1] => 0xA,
        b"B"[1] => 0xB,
        b"C"[1] => 0xC,
        b"D"[1] => 0xD,
        b"E"[1] => 0xE,
        b"F"[1] => 0xF,
    )
    for index in 1:indices
        int_val = 0
        for offset in 1:16
            hex_digit = raw_data[(index - 1) * 16 + offset]
            int_val = (int_val * 0x10) + digit_values[hex_digit]
        end
        result[index] = int_val / Float64(indices ÷ last(dimensions))
    end
    result
end

const PREGENERATED_1D4V_RES128 = _parse_generated_data(include("generated_1d4v_res128.jl"))
const PREGENERATED_1D4V_RES1024 = _parse_generated_data(include("generated_1d4v_res1024.jl"))
const PREGENERATED_1D4V_RES8192 = _parse_generated_data(include("generated_1d4v_res8192.jl"))
const PREGENERATED_1D4V_RES32768 = _parse_generated_data(include("generated_1d4v_res32768.jl"))
const PREGENERATED_1D4V = PREGENERATED_1D4V_RES32768

const PREGENERATED_2D4V_RES32 = _parse_generated_data(include("generated_2d4v_res32.jl"))
const PREGENERATED_2D4V_RES128 = _parse_generated_data(include("generated_2d4v_res128.jl"))
const PREGENERATED_2D4V_RES512 = _parse_generated_data(include("generated_2d4v_res512.jl"))
const PREGENERATED_2D4V_RES1024 = _parse_generated_data(include("generated_2d4v_res1024.jl"))
const PREGENERATED_2D4V = PREGENERATED_2D4V_RES1024

const PREGENERATED_3D4V_RES16 = _parse_generated_data(include("generated_3d4v_res16.jl"))
const PREGENERATED_3D4V_RES32 = _parse_generated_data(include("generated_3d4v_res32.jl"))
const PREGENERATED_3D4V_RES64 = _parse_generated_data(include("generated_3d4v_res64.jl"))
const PREGENERATED_3D4V = PREGENERATED_3D4V_RES64

blue_noise_1d4v(x::Int)::Vector{Float64} = PREGENERATED_1D4V[
    mod1(x, size(PREGENERATED_1D4V)[1]), 
    1:4
]

blue_noise_1d3v(x::Int)::Vector{Float64} = PREGENERATED_1D4V[
    mod1(x, size(PREGENERATED_1D4V)[1]), 
    1:3
]

blue_noise_1d2v(x::Int)::Vector{Float64} = PREGENERATED_1D4V[
    mod1(x, size(PREGENERATED_1D4V)[1]), 
    1:2
]

blue_noise_1d1v(x::Int)::Float64 = PREGENERATED_1D4V[
    mod1(x, size(PREGENERATED_1D4V)[1]), 
    1
]

blue_noise_2d4v(x::Int, y::Int)::Vector{Float64} = PREGENERATED_2D4V[
    mod1(x, size(PREGENERATED_2D4V)[1]), 
    mod1(y, size(PREGENERATED_2D4V)[2]), 
    1:4
]

blue_noise_2d3v(x::Int, y::Int)::Vector{Float64} = PREGENERATED_2D4V[
    mod1(x, size(PREGENERATED_2D4V)[1]), 
    mod1(y, size(PREGENERATED_2D4V)[2]), 
    1:3
]

blue_noise_2d2v(x::Int, y::Int)::Vector{Float64} = PREGENERATED_2D4V[
    mod1(x, size(PREGENERATED_2D4V)[1]), 
    mod1(y, size(PREGENERATED_2D4V)[2]), 
    1:2
]

blue_noise_2d1v(x::Int, y::Int)::Float64 = PREGENERATED_2D4V[
    mod1(x, size(PREGENERATED_2D4V)[1]), 
    mod1(y, size(PREGENERATED_2D4V)[2]), 
    1
]

blue_noise_3d4v(x::Int, y::Int, z::Int)::Vector{Float64} = PREGENERATED_3D4V[
    mod1(x, size(PREGENERATED_3D4V)[1]), 
    mod1(y, size(PREGENERATED_3D4V)[2]), 
    mod1(z, size(PREGENERATED_3D4V)[3]), 
    1:4
]

blue_noise_3d3v(x::Int, y::Int, z::Int)::Vector{Float64} = PREGENERATED_3D4V[
    mod1(x, size(PREGENERATED_3D4V)[1]), 
    mod1(y, size(PREGENERATED_3D4V)[2]), 
    mod1(z, size(PREGENERATED_3D4V)[3]), 
    1:3
]

blue_noise_3d2v(x::Int, y::Int, z::Int)::Vector{Float64} = PREGENERATED_3D4V[
    mod1(x, size(PREGENERATED_3D4V)[1]), 
    mod1(y, size(PREGENERATED_3D4V)[2]), 
    mod1(z, size(PREGENERATED_3D4V)[3]), 
    1:2
]

blue_noise_3d1v(x::Int, y::Int, z::Int)::Float64 = PREGENERATED_3D4V[
    mod1(x, size(PREGENERATED_3D4V)[1]), 
    mod1(y, size(PREGENERATED_3D4V)[2]), 
    mod1(z, size(PREGENERATED_3D4V)[3]), 
    1
]

export blue_noise_1d1v, blue_noise_1d2v, blue_noise_1d3v, blue_noise_1d4v
export blue_noise_2d1v, blue_noise_2d2v, blue_noise_2d3v, blue_noise_2d4v
export blue_noise_3d1v, blue_noise_3d2v, blue_noise_3d3v, blue_noise_3d4v

end # module
