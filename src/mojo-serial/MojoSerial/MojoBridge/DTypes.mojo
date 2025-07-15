from memory import bitcast

alias SizeType = UInt   # size_t
alias Short = Int16     # short
alias Float = Float32   # float
alias Double = Float64  # double

fn HexToFloat[fld: Int32]() -> Float:
    return bitcast[src_dtype=DType.int32, src_width=1, DType.float32](fld)

@always_inline
fn enumerate[T: Movable & Copyable](K: Span[T]) -> List[Tuple[Int, T]]:
    var L: List[Tuple[Int, T]] = []
    for i in range(len(K)):
        L.append((i, K[i]))
    return L
