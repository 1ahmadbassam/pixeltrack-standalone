from memory import bitcast, UnsafePointer

alias SizeType = UInt   # size_t
alias Short = Int16     # short
alias Float = Float32   # float
alias Double = Float64  # double

# Mojo Stable compatibility
alias OpaquePointer = UnsafePointer[NoneType]
alias NonePointer = OpaquePointer()

fn HexToFloat[fld: Int32]() -> Float:
    return bitcast[src_dtype=DType.int32, src_width=1, DType.float32](fld)
