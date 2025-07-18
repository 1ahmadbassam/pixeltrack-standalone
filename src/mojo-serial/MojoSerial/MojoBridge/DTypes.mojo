from memory import bitcast

alias SizeType = UInt  # size_t
alias Short = Int16  # short
alias Float = Float32  # float
alias Double = Float64  # double


# this trait is essential for supporting the framework
# currently, the framework uses some clever rebind trickery to bypass statically typed objects and store arbitrary objects within a container, but to have the same type flexibility, we must also be able to identify objects by type
trait Typeable:
    @always_inline
    @staticmethod
    fn dtype() -> String:
        ...


fn HexToFloat[fld: Int32]() -> Float:
    return bitcast[src_dtype = DType.int32, src_width=1, DType.float32](fld)


@always_inline
fn enumerate[T: Movable & Copyable](K: Span[T]) -> List[Tuple[Int, T]]:
    var L: List[Tuple[Int, T]] = []
    for i in range(len(K)):
        L.append((i, K[i]))
    return L
