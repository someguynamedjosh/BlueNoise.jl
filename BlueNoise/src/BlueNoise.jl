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

const PREGENERATED_D1V4_RES128 = _parse_generated_data(include("generated_d1v4_res128.jl"))
const PREGENERATED_D1V4_RES1024 = _parse_generated_data(include("generated_d1v4_res1024.jl"))
const PREGENERATED_D1V4_RES8192 = _parse_generated_data(include("generated_d1v4_res8192.jl"))
const PREGENERATED_D1V4_RES32768 = _parse_generated_data(include("generated_d1v4_res32768.jl"))
const PREGENERATED_D1V4 = PREGENERATED_D1V4_RES32768

const PREGENERATED_D2V4_RES32 = _parse_generated_data(include("generated_d2v4_res32.jl"))
const PREGENERATED_D2V4_RES128 = _parse_generated_data(include("generated_d2v4_res128.jl"))
const PREGENERATED_D2V4_RES512 = _parse_generated_data(include("generated_d2v4_res512.jl"))
const PREGENERATED_D2V4_RES1024 = _parse_generated_data(include("generated_d2v4_res1024.jl"))
const PREGENERATED_D2V4 = PREGENERATED_D2V4_RES1024

const PREGENERATED_D3V4_RES16 = _parse_generated_data(include("generated_d3v4_res16.jl"))
const PREGENERATED_D3V4_RES32 = _parse_generated_data(include("generated_d3v4_res32.jl"))
const PREGENERATED_D3V4_RES64 = _parse_generated_data(include("generated_d3v4_res64.jl"))
const PREGENERATED_D3V4 = PREGENERATED_D3V4_RES64

blue_noise_d1v4(x::Int)::Vector{Float64} = PREGENERATED_D1V4[
    mod1(x, size(PREGENERATED_D1V4)[1]), 
    1:4
]

blue_noise_d1v3(x::Int)::Vector{Float64} = PREGENERATED_D1V4[
    mod1(x, size(PREGENERATED_D1V4)[1]), 
    1:3
]

blue_noise_d1v2(x::Int)::Vector{Float64} = PREGENERATED_D1V4[
    mod1(x, size(PREGENERATED_D1V4)[1]), 
    1:2
]

blue_noise_d1v1(x::Int)::Float64 = PREGENERATED_D1V4[
    mod1(x, size(PREGENERATED_D1V4)[1]), 
    1
]

blue_noise_d2v4(x::Int, y::Int)::Vector{Float64} = PREGENERATED_D2V4[
    mod1(x, size(PREGENERATED_D2V4)[1]), 
    mod1(y, size(PREGENERATED_D2V4)[2]), 
    1:4
]

blue_noise_d2v3(x::Int, y::Int)::Vector{Float64} = PREGENERATED_D2V4[
    mod1(x, size(PREGENERATED_D2V4)[1]), 
    mod1(y, size(PREGENERATED_D2V4)[2]), 
    1:3
]

blue_noise_d2v2(x::Int, y::Int)::Vector{Float64} = PREGENERATED_D2V4[
    mod1(x, size(PREGENERATED_D2V4)[1]), 
    mod1(y, size(PREGENERATED_D2V4)[2]), 
    1:2
]

blue_noise_d2v1(x::Int, y::Int)::Float64 = PREGENERATED_D2V4[
    mod1(x, size(PREGENERATED_D2V4)[1]), 
    mod1(y, size(PREGENERATED_D2V4)[2]), 
    1
]

blue_noise_d3v4(x::Int, y::Int, z::Int)::Vector{Float64} = PREGENERATED_D3V4[
    mod1(x, size(PREGENERATED_D3V4)[1]), 
    mod1(y, size(PREGENERATED_D3V4)[2]), 
    mod1(z, size(PREGENERATED_D3V4)[3]), 
    1:4
]

blue_noise_d3v3(x::Int, y::Int, z::Int)::Vector{Float64} = PREGENERATED_D3V4[
    mod1(x, size(PREGENERATED_D3V4)[1]), 
    mod1(y, size(PREGENERATED_D3V4)[2]), 
    mod1(z, size(PREGENERATED_D3V4)[3]), 
    1:3
]

blue_noise_d3v2(x::Int, y::Int, z::Int)::Vector{Float64} = PREGENERATED_D3V4[
    mod1(x, size(PREGENERATED_D3V4)[1]), 
    mod1(y, size(PREGENERATED_D3V4)[2]), 
    mod1(z, size(PREGENERATED_D3V4)[3]), 
    1:2
]

blue_noise_d3v1(x::Int, y::Int, z::Int)::Float64 = PREGENERATED_D3V4[
    mod1(x, size(PREGENERATED_D3V4)[1]), 
    mod1(y, size(PREGENERATED_D3V4)[2]), 
    mod1(z, size(PREGENERATED_D3V4)[3]), 
    1
]

export blue_noise_d1v1, blue_noise_d1v2, blue_noise_d1v3, blue_noise_d1v4
export blue_noise_d2v1, blue_noise_d2v2, blue_noise_d2v3, blue_noise_d2v4
export blue_noise_d3v1, blue_noise_d3v2, blue_noise_d3v3, blue_noise_d3v4

end # module
