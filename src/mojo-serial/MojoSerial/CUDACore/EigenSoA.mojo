from memory import UnsafePointer

from MojoSerial.MojoBridge.Array import Array
from MojoSerial.MojoBridge.DTypes import Typeable


fn isPowerOf2(v: Int32) -> Bool:
    return v and not (v & (v - 1))


# TODO: Figure out how to align this struct
struct ScalarSoA[T: DType, S: Int](Copyable, Defaultable, Movable, Typeable):
    alias Scalar = Scalar[T]
    var _data: Array[Self.Scalar, S]

    @always_inline
    fn __init__(out self):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()
        self._data = Array[Self.Scalar, S](0)

    fn __init__(out self, list: List[Self.Scalar]):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()
        self = Self()
        for i in range(min(S, list.__len__())):
            self._data[i] = list[i]

    @always_inline
    fn __init__(out self, owned list: Array[Self.Scalar, S]):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()
        self._data = list^

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._data = other._data^

    @always_inline
    fn __copyinit__(out self, other: Self):
        self._data = other._data

    @always_inline
    fn data(ref self) -> UnsafePointer[Self.Scalar, mut=False]:
        return self._data.unsafe_ptr()

    @always_inline
    fn __getitem__(ref self, i: Int) -> ref [self._data] Self.Scalar:
        return self._data[i]

    @always_inline
    fn __setitem__(mut self, i: Int, v: Self.Scalar):
        self._data[i] = v

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "ScalarSoA[" + T.__repr__() + ", " + String(S) + "]"


# TODO: Find out how to align this struct
# TODO: Implement SoA on a list of matrices or vectors
#       Since we control these types, it should not be impossible
#       The current implementation does not expose elements of a vector or a matrix appropriately for an SoA representation
# struct MatrixSoA(Typeable):
#     pass
alias MatrixSoA = Array
