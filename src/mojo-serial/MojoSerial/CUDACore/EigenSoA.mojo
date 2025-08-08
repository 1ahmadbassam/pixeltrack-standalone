from layout import Layout, LayoutTensor, IntTuple

from MojoSerial.MojoBridge.DTypes import Typeable


fn isPowerOf2(v: Int32) -> Bool:
    return v and not (v & (v - 1))


# WARNING: THIS STRUCT IS 128-ALIGNED
struct ScalarSoA[T: DType, S: Int](
    Copyable, Defaultable, Movable, Sized, Typeable
):
    alias Scalar = Scalar[T]
    var _data: InlineArray[Self.Scalar, S]

    @always_inline
    fn __init__(out self):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()
        self._data = InlineArray[Self.Scalar, S](fill=0)

    @always_inline
    fn __init__(out self, var list: InlineArray[Self.Scalar, S]):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()
        self._data = list^

    @always_inline
    fn __init__(
        out self, var ptr: UnsafePointer[Self.Scalar], *, var cp: Bool = False
    ):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()

        self._data = InlineArray[Self.Scalar, S](uninitialized=True)

        for i in range(S):
            if cp:
                (self._data.unsafe_ptr() + i).init_pointee_copy((ptr + i)[])
            else:
                (self._data.unsafe_ptr() + i).init_pointee_move(
                    (ptr + i).take_pointee()
                )

    @always_inline
    fn __len__(self) -> Int:
        return S

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self._data = other._data^

    @always_inline
    fn __copyinit__(out self, other: Self):
        self._data = other._data

    @always_inline
    fn data[
        origin: Origin, //
    ](ref [origin]self) -> UnsafePointer[
        Self.Scalar, mut = origin.mut, origin=origin
    ]:
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


# WARNING: THIS STRUCT IS 128-ALIGNED
struct MatrixSoA[T: DType, R: Int, C: Int, S: Int](
    Copyable, Defaultable, Movable, Sized, Typeable
):
    alias Scalar = Scalar[T]
    alias _D = InlineArray[Self.Scalar, S * R * C]
    alias Map = Layout(IntTuple(R, C), IntTuple(R * S, S))
    var _data: Self._D

    @always_inline
    fn __init__(out self):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            R * C * S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()
        self._data = Self._D(fill=0)

    @always_inline
    fn __init__(out self, var list: Self._D):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            R * C * S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()
        self._data = list^

    @always_inline
    fn __init__(
        out self, var ptr: UnsafePointer[Self.Scalar], *, var cp: Bool = False
    ):
        constrained[isPowerOf2(S), "SoA stride not a power of 2"]()
        constrained[
            R * C * S * T.sizeof() % 128 == 0, "SoA size not a multiple of 128"
        ]()

        self._data = Self._D(uninitialized=True)

        for i in range(R * C * S):
            if cp:
                (self._data.unsafe_ptr() + i).init_pointee_copy((ptr + i)[])
            else:
                (self._data.unsafe_ptr() + i).init_pointee_move(
                    (ptr + i).take_pointee()
                )

    @always_inline
    fn __len__(self) -> Int:
        return R * C * S

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self._data = other._data^

    @always_inline
    fn __copyinit__(out self, other: Self):
        self._data = other._data

    @always_inline
    fn __getitem__[
        origin: Origin, //
    ](ref [origin]self, i: Int32) -> LayoutTensor[
        mut = origin.mut, T, Self.Map, origin
    ]:
        return LayoutTensor[mut = origin.mut, T, Self.Map, origin](
            self._data.unsafe_ptr() + i
        )

    # TODO: __setitem__

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return (
            "MatrixSoA["
            + T.__repr__()
            + ", "
            + String(R)
            + ", "
            + String(C)
            + ", "
            + String(S)
            + "]"
        )
