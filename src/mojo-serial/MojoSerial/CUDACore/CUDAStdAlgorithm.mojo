from memory import UnsafePointer
from sys.info import sizeof


fn lower_bound[
    T: DType, //
](
    mut first: UnsafePointer[Scalar[T]],
    last: UnsafePointer[Scalar[T]],
    ref value: Scalar[T],
) -> UnsafePointer[Scalar[T]]:
    var count = (Int(last) - Int(first)) // sizeof[Scalar[T]]()

    while count > 0:
        var it = first
        var step = count // 2
        it += step

        if it[] < value:
            it += 1
            first = it
            count -= step + 1
        else:
            count = step

    return first


fn upper_bound[
    T: DType, //
](
    mut first: UnsafePointer[Scalar[T]],
    last: UnsafePointer[Scalar[T]],
    ref value: Scalar[T],
) -> UnsafePointer[Scalar[T]]:
    var count = (Int(last) - Int(first)) // sizeof[Scalar[T]]()

    while count > 0:
        var it = first
        var step = count // 2
        it += step

        if it[] <= value:
            it += 1
            first = it
            count -= step + 1
        else:
            count = step

    return first


fn binary_find[
    T: DType, //
](
    mut first: UnsafePointer[Scalar[T]],
    last: UnsafePointer[Scalar[T]],
    ref value: Scalar[T],
) -> UnsafePointer[Scalar[T]]:
    first = lower_bound(first, last, value)

    if (first != last) and (value >= first[]):
        return first
    return last
