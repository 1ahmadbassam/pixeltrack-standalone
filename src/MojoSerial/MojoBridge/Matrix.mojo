from MojoSerial.MojoBridge.Vector import Vector

struct Matrix[T: DType, rows: Int, colns: Int](Defaultable):
    alias _R = Vector[T, colns]
    alias _D = Scalar[T]
    alias _DC = InlineArray[Vector[T, colns], rows]
    var _data: Self._DC

    # Lifecycle methods
    @always_inline
    fn __init__(out self):
        """Default constructor."""
        self._data = Self._DC(Self._R())

    # Operators

    fn __getitem__(self, i: Int, j: Int) -> Self._D:
        return self._data[i][j]

    fn __setitem__(mut self, i: Int, j: Int, val: Self._D):
        self._data[i][j] = val

    # TODO: Finish this class
