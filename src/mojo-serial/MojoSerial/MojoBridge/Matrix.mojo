from sys import alignof, is_gpu
from utils.numerics import max_finite as _max_finite
from utils.numerics import max_or_inf as _max_or_inf
from utils.numerics import min_finite as _min_finite
from utils.numerics import min_or_neg_inf as _min_or_neg_inf

from MojoSerial.MojoBridge.Vector import Vector
from MojoSerial.MojoBridge.Stable import Iterator, OpaquePointer

@fieldwise_init
struct _MatIterator[
    mat_mutability: Bool, //,
    W: DType,
    rows: Int,
    colns: Int,
    mat_origin: Origin[mat_mutability],
    forward: Bool = True,
    row_wise: Bool = True
](Copyable, Iterator, Movable):
    alias mat_type = Matrix[W, rows, colns]
    alias T = Scalar[W]
    alias Element = Self.T

    var index: Int
    var src: Pointer[Self.mat_type, mat_origin]

    fn __next_ref__(mut self) -> Self.T:
        @parameter
        if forward:
            self.index += 1
            return self.src[][self.index - 1, row_wise]
        else:
            self.index -= 1
            return self.src[][self.index, row_wise]

    @always_inline
    fn __next__(mut self) -> Self.T:
        return self.__next_ref__()

    @always_inline
    fn __has_next__(self) -> Bool:
        return self.__len__() > 0

    @always_inline
    fn __iter__(self) -> Self:
        return self

    fn __len__(self) -> Int:
        @parameter
        if forward:
            return len(self.src[]) - self.index
        else:
            return self.index

# A comment about this implementation: it is probably the speediest, but arguably not of the best memory efficiency (?)
# Handling rows in a SIMD structure does give rows immense advantage over columns, it also simplfies implementation... but we are still using InlineArray for memory
# TODO: Is implementing a matrix as an inline array of vectors faster or slower than a direct memory implementation using an unsafe pointer?
struct Matrix[T: DType, rows: Int, colns: Int](
    Defaultable,
    Movable,
    Copyable,
    ExplicitlyCopyable,
    Sized
):
    alias _L = List[List[Scalar[T]]]
    alias _LS = InlineArray[InlineArray[Scalar[T], colns], rows]
    alias _R = Vector[T, colns]
    alias _D = Scalar[T]
    alias _DC = InlineArray[Vector[T, colns], rows]
    alias _Mask = Matrix[DType.bool, rows, colns]
    var _data: Self._DC

    # SIMD specifics

    alias device_type: AnyType = Self

    fn _to_device_type(self, target: OpaquePointer):
        target.bitcast[Self.device_type]()[] = self

    @staticmethod
    fn get_type_name() -> String:
        return "Matrix[" + repr(T) + ", " + repr(rows) + ", " + repr(colns) + "]"

    @staticmethod
    fn get_device_type_name() -> String:
        return Self.get_type_name()

    alias MAX = Self(_max_or_inf[T]())
    alias MIN = Self(_min_or_neg_inf[T]())
    alias MAX_FINITE = Self(_max_finite[T]())
    alias MIN_FINITE = Self(_min_finite[T]())

    alias _default_alignment = alignof[Self._D]() if is_gpu() else 1

    @doc_private
    @always_inline("nodebug")
    @implicit
    fn __init__(out self, value: __mlir_type.index, /):
        # support MLIR assignment for compatibility purposes
        self._data = Self._DC(value)

    # Lifecycle methods
    @always_inline
    fn __init__(out self):
        """Default constructor."""
        self._data = Self._DC(Self._R())
    
    @always_inline
    fn copy(self) -> Self:
        """Explicitly construct a copy of self."""
        return Self.__copyinit__(self)
        
    @always_inline
    fn __init__[U: DType, //](out self, *, owned row: Vector[U, colns]):
        """Initialize a matrix from a Vector row object of the same coln-size, splattered across all rows."""
        self._data = Self._DC(Self._R(row))

    @always_inline
    fn __init__[U: DType, //](out self, *, owned coln: Vector[U, colns]):
        """Initialize a matrix from a Vector coln object of the same row-size, splattered across all columns."""
        self = Self()
        @parameter
        for i in range(rows):
            @parameter
            for j in range(colns):
                self[i, j] = coln[i].cast[T]()

    @always_inline
    fn __init__[U: DType, //](out self, val: Scalar[U], /):
        """Initializes a matrix with a scalar. 
        The scalar is splatted across all the elements of the matrix."""
        self._data = Self._DC(Self._R(val))

    @always_inline
    fn __init__(out self, val: Int, /):
        """Initializes a matrix with a signed integer. 
        The signed integer is splatted across all the elements of the matrix."""
        self._data = Self._DC(Self._R(val))

    @always_inline
    fn __init__(out self, val: UInt, /):
        """Initializes a matrix with a unsigned integer. 
        The unsigned integer is splatted across all the elements of the matrix."""
        self._data = Self._DC(Self._R(val))

    @always_inline
    @implicit
    fn __init__(out self, val: IntLiteral, /):
        """Initializes a matrix with an integer literal (implicit). 
        The integer literal is splatted across all the elements of the matrix."""
        self._data = Self._DC(Self._R(val))

    @always_inline
    @implicit
    fn __init__(out self, *values: Self._D, __list_literal__: () = ()):
        """Constructs a matrix via a variadic list of values in a literal format."""
        self = Self()
        for i in range(values.__len__()):
            self[i] = values[i]

    @always_inline
    @implicit
    fn __init__(out self, *values: VariadicList[Self._D], __list_literal__: () = ()):
        """Constructs a matrix via a variadic list of variadic values in a literal format."""
        self = Self()
        for i in range(values.__len__()):
            for j in range(values[0].__len__()):
                self[i, j] = values[i][j]

    @implicit
    fn __init__(out self, mat: Self._L):
        """Constructs a matrix via a matrix list representation."""
        self = Self()
        if mat:
            for i in range(min(rows, mat.__len__())):
                for j in range(min(colns, mat[0].__len__())):
                    self[i, j] = mat[i][j]

    @implicit
    fn __init__(out self, mat: Self._LS):
        """Constructs a matrix via a matrix inline array representation."""
        self = Self()
        @parameter
        for i in range(rows):
            @parameter
            for j in range(colns):
                self[i, j] = mat[i][j]

    fn __init__[vrows: Int, vcolns: Int, //](out self, mat: Matrix[T, vrows, vcolns]):
        """Initialize a matrix from an arbitrary matrix. Might cause data loss."""
        self = Self()
        @parameter
        for i in range(min(rows * colns, vrows * vcolns)):
            self[i] = mat[i]

    fn __init__[U: DType, //](out self, mat: Matrix[U, rows, colns]):
        """Initialize a matrix from a matrix of the same size of a different data type."""
        self = Self()
        @parameter
        for i in range(rows * colns):
            self[i] = mat[i].cast[T]()

    # Compatibility with V1 Matricies

    fn __init__[vsize: Int, //](out self, vec: Vector[T, vsize]):
        """Initialize a matrix from an arbitrary vector (V1 format). Might cause data loss."""
        self = Self()
        @parameter
        for i in range(min(rows * colns, vsize)):
            self[i] = vec[i]

    @implicit
    fn __init__(out self, values: List[Self._D], /):
        """Initialize a matrix from a list of values. Might cause data loss."""
        self = Self()
        for i in range(min(self.__len__(), values.__len__())):
            self[i] = values[i]

    @always_inline
    fn __getitem__(self, i: Int, row_wise: Bool = True) -> Self._D:
        if row_wise:
            return self._data[i // colns][i % colns]
        else:
            return self._data[i % rows][i // rows]

    @always_inline
    fn __setitem__(mut self, i: Int, val: Self._D):
            self._data[i // colns][i % colns] = val

    @always_inline
    fn __setitem__(mut self, i: Int, row_wise: Bool, val: Self._D):
        if row_wise:
            self._data[i // colns][i % colns] = val
        else:
            self._data[i % rows][i // rows] = val

    @always_inline
    fn __len__(self) -> Int:
        return rows * colns

    # Operators

    @always_inline
    fn __getitem__(self, i: Int, j: Int) -> Self._D:
        return self._data[i][j]

    @always_inline
    fn __setitem__(mut self, i: Int, j: Int, val: Self._D):
        self._data[i][j] = val

    fn __iter__(ref self) -> _MatIterator[T, rows, colns, __origin_of(self)]:
        return _MatIterator[T, rows, colns, __origin_of(self)](0, Pointer(to=self))

    @always_inline
    fn __contains__(self, value: Self._D) -> Bool:
        var res: Bool = False
        @parameter
        for i in range(rows):
            res = res and self._data[i].__contains__(value)
            if res:
                return res
        return res

    @always_inline
    fn __add__(self, rhs: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] + rhs._data[i]
        return res

    @always_inline
    fn __sub__(self, rhs: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] - rhs._data[i]
        return res

    @always_inline
    fn __mul__(self, rhs: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] * rhs._data[i]
        return res

    @no_inline
    fn __matmul__[trp: Int, //](self, rhs: Matrix[T, colns, trp]) -> Matrix[T, rows, trp]:
        var res: Matrix[T, rows, trp] = Matrix[T, rows, trp]()
        @parameter
        for i in range(rows):
            @parameter
            for j in range(trp):
                res[i, j] = self._row_by_coln(rhs, i, j)
        return res

    @always_inline
    fn __truediv__(self, rhs: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] / rhs._data[i]
        return res
    
    @always_inline
    fn __floordiv__(self, rhs: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] // rhs._data[i]
        return res

    @always_inline
    fn __mod__(self, rhs: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] % rhs._data[i]
        return res

    @no_inline
    fn __pow__[sq: Int, //](self: Matrix[T, sq, sq], exp: Int) -> Matrix[T, sq, sq]:
        if exp < 0:
            return ~self ** -exp
        elif exp == 0:
            return Matrix[T, sq, sq].identity()
        elif exp == 1:
            return self
        var res: Matrix[T, sq, sq] = self
        for _ in range(2, exp + 1):
            res = self @ res
        return res

    @always_inline
    fn __lt__(self, rhs: Self) -> Self._Mask:
        var res: Self._Mask = Self._Mask()
        @parameter
        for i in range(rows):
            res._data[i] = self._data[i] < rhs._data[i]
        return res

    @always_inline
    fn __le__(self, rhs: Self) -> Self._Mask:
        var res: Self._Mask = Self._Mask()
        @parameter
        for i in range(rows):
            res._data[i] = self._data[i] <= rhs._data[i]
        return res

    @always_inline
    fn __eq__(self, rhs: Self) -> Self._Mask:
        var res: Self._Mask = Self._Mask()
        @parameter
        for i in range(rows):
            res._data[i] = self._data[i] == rhs._data[i]
        return res

    @always_inline
    fn __ne__(self, rhs: Self) -> Self._Mask:
        var res: Self._Mask = Self._Mask()
        @parameter
        for i in range(rows):
            res._data[i] = self._data[i] != rhs._data[i]
        return res

    @always_inline
    fn __gt__(self, rhs: Self) -> Self._Mask:
        var res: Self._Mask = Self._Mask()
        @parameter
        for i in range(rows):
            res._data[i] = self._data[i] > rhs._data[i]
        return res

    @always_inline
    fn __ge__(self, rhs: Self) -> Self._Mask:
        var res: Self._Mask = Self._Mask()
        @parameter
        for i in range(rows):
            res._data[i] = self._data[i] >= rhs._data[i]
        return res

    @always_inline
    fn __pos__(self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        return self

    @always_inline
    fn __neg__(self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        var res = self
        @parameter
        for i in range(rows):
            res[i] = -res[i]
        return res

    @always_inline
    fn __and__(self, rhs: Self) -> Self:
        constrained[
            T.is_integral() or T is DType.bool,
            "DType must be an integral or bool type",
        ]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] & rhs._data[i]
        return res

    @always_inline
    fn __xor__(self, rhs: Self) -> Self:
        constrained[
            T.is_integral() or T is DType.bool,
            "DType must be an integral or bool type",
        ]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] ^ rhs._data[i]
        return res

    @always_inline
    fn __or__(self, rhs: Self) -> Self:
        constrained[
            T.is_integral() or T is DType.bool,
            "DType must be an integral or bool type",
        ]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] | rhs._data[i]
        return res

    @always_inline
    fn __lshift__(self, rhs: Self) -> Self:
        constrained[T.is_integral(), "DType must be an integral type"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] << rhs._data[i]
        return res

    @always_inline
    fn __rshift__(self, rhs: Self) -> Self:
        constrained[T.is_integral(), "DType must be an integral type"]()
        var res = self
        @parameter
        for i in range(rows):
            res._data[i] = res._data[i] >> rhs._data[i]
        return res

    @no_inline
    fn __invert__(self) -> Self:
        # TODO: Implement Inverse
        return self

    # In place operations

    @always_inline("nodebug")
    fn __iadd__(mut self, rhs: Self):
        constrained[T.is_numeric(), "DType must be numeric"]()
        self = self + rhs

    @always_inline("nodebug")
    fn __isub__(mut self, rhs: Self):
        constrained[T.is_numeric(), "DType must be numeric"]()
        self = self - rhs

    @always_inline("nodebug")
    fn __imul__(mut self, rhs: Self):
        constrained[T.is_numeric(), "DType must be numeric"]()
        self = self * rhs

    @always_inline("nodebug")
    fn __itruediv__(mut self, rhs: Self):
        constrained[T.is_numeric(), "DType must be numeric"]()
        self = self / rhs

    @always_inline("nodebug")
    fn __ifloordiv__(mut self, rhs: Self):
        constrained[T.is_numeric(), "DType must be numeric"]()
        self = self // rhs

    @always_inline("nodebug")
    fn __imod__(mut self, rhs: Self):
        constrained[T.is_numeric(), "DType must be numeric"]()
        self = self.__mod__(rhs)

    @always_inline("nodebug")
    fn __ipow__[sq: Int, //](mut self: Matrix[T, sq, sq], rhs: Int):
        constrained[T.is_numeric(), "DType must be numeric"]()
        self = self.__pow__(rhs)

    @always_inline("nodebug")
    fn __iand__(mut self, rhs: Self):
        constrained[
            T.is_integral() or T is DType.bool,
            "DType must be an integral or bool type",
        ]()
        self = self & rhs

    @always_inline("nodebug")
    fn __ixor__(mut self, rhs: Self):
        constrained[
            T.is_integral() or T is DType.bool,
            "DType must be an integral or bool type",
        ]()
        self = self ^ rhs

    @always_inline("nodebug")
    fn __ior__(mut self, rhs: Self):
        constrained[
            T.is_integral() or T is DType.bool,
            "DType must be an integral or bool type",
        ]()
        self = self | rhs

    @always_inline("nodebug")
    fn __ilshift__(mut self, rhs: Self):
        constrained[T.is_integral(), "DType must be an integral type"]()
        self = self << rhs

    @always_inline("nodebug")
    fn __irshift__(mut self, rhs: Self):
        constrained[T.is_integral(), "DType must be an integral type"]()
        self = self >> rhs

    @always_inline("nodebug")
    fn __iinvert__(mut self):
        constrained[
            T.is_integral() or T is DType.bool,
            "DType must be an integral or bool type",
        ]()
        self = ~self        

    # Reversed operations
    
    @always_inline
    fn __radd__(self, value: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        return value + self

    @always_inline
    fn __rsub__(self, value: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        return value - self

    @always_inline
    fn __rmul__(self, value: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        return value * self

    @always_inline
    fn __rfloordiv__(self, rhs: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        return rhs // self

    @always_inline
    fn __rtruediv__(self, value: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        return value / self

    @always_inline
    fn __rmod__(self, value: Self) -> Self:
        constrained[T.is_numeric(), "DType must be numeric"]()
        return value % self

    @always_inline
    fn __rand__(self, value: Self) -> Self:
        constrained[
            T.is_integral() or T is DType.bool,
            "DType be an integral or bool type",
        ]()
        return value & self

    @always_inline
    fn __rxor__(self, value: Self) -> Self:
        constrained[
            T.is_integral() or T is DType.bool,
            "DType be an integral or bool type",
        ]()
        return value ^ self

    @always_inline
    fn __ror__(self, value: Self) -> Self:
        constrained[
            T.is_integral() or T is DType.bool,
            "DType be an integral or bool type",
        ]()
        return value | self

    @always_inline
    fn __rlshift__(self, value: Self) -> Self:
        constrained[T.is_integral(), "DType be an integral type"]()
        return value << self

    @always_inline
    fn __rrshift__(self, value: Self) -> Self:
        constrained[T.is_integral(), "DType be an integral type"]()
        return value >> self    

    # Trait conformance
    

    # Methods

    fn row_iterator(ref self) -> _MatIterator[T, rows, colns, __origin_of(self)]:
        return _MatIterator[T, rows, colns, __origin_of(self)](0, Pointer(to=self))

    fn coln_iterator(ref self) -> _MatIterator[T, rows, colns, __origin_of(self), row_wise=False]:
        return _MatIterator[T, rows, colns, __origin_of(self), row_wise=False](0, Pointer(to=self))

    @always_inline
    fn row(self, i: Int) -> Vector[T, colns]:
        return self._data[i]
    
    @no_inline
    fn coln(self, j: Int) -> Vector[T, rows]:
        var res: Vector[T, rows] = Vector[T, rows]()
        @parameter
        for i in range(rows):
            res[i] = self[i, j]
        return res

    @no_inline
    fn _row_by_coln(self, other: Matrix[T, colns, _], row: Int, coln: Int) -> Self._D:
        constrained[T.is_integral(), "DType must be an integral type"]()
        var sum: Self._D = 0
        @parameter
        for i in range(colns):
            sum += self[row, i] * other[i, coln]
        return sum

    @no_inline
    fn transpose(self) -> Matrix[T, colns, rows]:
        var res = Matrix[T, colns, rows]()
        @parameter
        for i in range(colns):
            @parameter
            for j in range(rows):
                res[i, j] = self[j, i]
        return res

    @staticmethod
    @no_inline
    fn identity() -> Self:
        constrained[rows == colns, "Identity can only be a square matrix"]()
        var res: Self = Self()
        for i in range(rows):
            res[i, i] = 1
        return res

    @always_inline
    fn inverse(self) -> Self:
        return ~self
    
    # TODO: Finish this class
