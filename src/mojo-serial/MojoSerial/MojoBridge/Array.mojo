import math
from collections._index_normalization import normalize_index
from sys.intrinsics import _type_is_eq

from memory import UnsafePointer
from memory.maybe_uninitialized import UnsafeMaybeUninitialized


# this has to exist because for some reason
# Mojo's move for arrays is COPYING
# HOW CAN YOU EVEN MAKE A BUG LIKE THIS!!
# replace in next stable release

# ===-----------------------------------------------------------------------===#
# Array
# ===-----------------------------------------------------------------------===#


fn _inline_array_construction_checks[size: Int]():
    constrained[size > 0, "number of elements in `Array` must be > 0"]()

struct Array[
    ElementType: Copyable & Movable,
    size: Int,
    *,
    run_destructors: Bool = False,
](Copyable, Defaultable, ExplicitlyCopyable, Movable, Sized):
    # Fields
    alias type = __mlir_type[
        `!pop.array<`, size.value, `, `, Self.ElementType, `>`
    ]
    var _array: Self.type

    @always_inline
    fn __init__(out self):
        constrained[
            False,
            (
                "Initialize with either a variadic list of arguments, a default"
                " fill element or pass the keyword argument"
                " 'unsafe_uninitialized'."
            ),
        ]()
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

    @always_inline
    fn __init__(out self, *, uninitialized: Bool):
        _inline_array_construction_checks[size]()
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

    fn __init__(
        out self,
        *,
        owned unsafe_assume_initialized: Array[
            UnsafeMaybeUninitialized[Self.ElementType], Self.size
        ],
    ):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        for i in range(Self.size):
            unsafe_assume_initialized[i].unsafe_ptr().move_pointee_into(
                self.unsafe_ptr() + i
            )

    @always_inline
    @implicit
    fn __init__[batch_size: Int = 64](out self, fill: Self.ElementType):
        _inline_array_construction_checks[size]()
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

        alias unroll_end = math.align_down(size, batch_size)

        var ptr = self.unsafe_ptr()

        for _ in range(0, unroll_end, batch_size):

            @parameter
            for _ in range(batch_size):
                ptr.init_pointee_copy(fill)
                ptr += 1

        # Fill the remainder
        @parameter
        for _ in range(unroll_end, size):
            ptr.init_pointee_copy(fill)
            ptr += 1
        debug_assert(
            ptr == self.unsafe_ptr().offset(size),
            "error during `Array` initialization , please file a bug",
            " report.",
        )

    @always_inline
    @implicit
    fn __init__(
        out self, owned *elems: Self.ElementType, __list_literal__: () = ()
    ):
        self = Self(storage=elems^)

    @always_inline
    fn __init__(
        out self,
        *,
        owned storage: VariadicListMem[Self.ElementType, _],
    ):
        debug_assert(
            len(storage) == size,
            "Expected variadic list of length ",
            size,
            ", received ",
            len(storage),
        )
        _inline_array_construction_checks[size]()
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

        var ptr = self.unsafe_ptr()

        # Move each element into the array storage.
        @parameter
        for i in range(size):
            UnsafePointer(to=storage[i]).move_pointee_into(ptr)
            ptr += 1

        # Do not destroy the elements when their backing storage goes away.
        __disable_del storage

    fn copy(self) -> Self:
        var copy = Self(uninitialized=True)

        for idx in range(size):
            var ptr = copy.unsafe_ptr() + idx
            ptr.init_pointee_copy(self[idx])

        return copy^

    fn __copyinit__(out self, other: Self):
        self = other.copy()

    fn __del__(owned self):
        @parameter
        if Self.run_destructors:

            @parameter
            for idx in range(size):
                var ptr = self.unsafe_ptr() + idx
                ptr.destroy_pointee()

    fn __moveinit__(out self, owned other: Self):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

        for idx in range(size):
            var other_ptr = other.unsafe_ptr() + idx
            other_ptr.move_pointee_into(self.unsafe_ptr() + idx)

    # ===------------------------------------------------------------------===#
    # Operator dunders
    # ===------------------------------------------------------------------===#

    @always_inline
    fn __getitem__[I: Indexer](ref self, idx: I) -> ref [self] Self.ElementType:
        var normalized_index = normalize_index["Array"](idx, len(self))
        return self.unsafe_get(normalized_index)

    @always_inline
    fn __getitem__[
        I: Indexer, //, idx: I
    ](ref self) -> ref [self] Self.ElementType:
        constrained[-size <= Int(idx) < size, "Index must be within bounds."]()
        alias normalized_index = normalize_index["Array"](idx, size)
        return self.unsafe_get(normalized_index)

    # ===------------------------------------------------------------------=== #
    # Trait implementations
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __len__(self) -> Int:
        return size

    # ===------------------------------------------------------------------===#
    # Methods
    # ===------------------------------------------------------------------===#

    @always_inline
    fn unsafe_get[I: Indexer](ref self, idx: I) -> ref [self] Self.ElementType:
        var i = index(idx)
        debug_assert(
            0 <= Int(i) < size,
            " Array.unsafe_get() index out of bounds: ",
            Int(idx),
            " should be less than: ",
            size,
        )
        var ptr = __mlir_op.`pop.array.gep`(
            UnsafePointer(to=self._array).address,
            i,
        )
        return UnsafePointer(ptr)[]

    @always_inline
    fn unsafe_ptr(
        ref self,
    ) -> UnsafePointer[
        Self.ElementType,
        mut = Origin(__origin_of(self)).mut,
        origin = __origin_of(self),
    ]:
        return (
            UnsafePointer(to=self._array)
            .bitcast[Self.ElementType]()
            .origin_cast[
                mut = Origin(__origin_of(self)).mut, origin = __origin_of(self)
            ]()
        )

    @always_inline
    fn __contains__[
        T: EqualityComparable & Copyable & Movable, //
    ](self: Array[T, size], value: T) -> Bool:
        @parameter
        for i in range(size):
            if self[i] == value:
                return True
        return False