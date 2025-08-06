from sys import sizeof


fn lower_bound[
    T: DType, //
](
    first: UnsafePointer[Scalar[T]],
    last: UnsafePointer[Scalar[T]],
    ref value: Scalar[T],
) -> UnsafePointer[Scalar[T]]:
    var _first = first
    var count = (Int(last) - Int(_first)) // sizeof[Scalar[T]]()

    while count > 0:
        var it = _first
        var step = count // 2
        it += step

        if it[] < value:
            it += 1
            _first = it
            count -= step + 1
        else:
            count = step

    return _first


fn upper_bound[
    T: DType, //
](
    first: UnsafePointer[Scalar[T]],
    last: UnsafePointer[Scalar[T]],
    ref value: Scalar[T],
) -> UnsafePointer[Scalar[T]]:
    var _first = first
    var count = (Int(last) - Int(_first)) // sizeof[Scalar[T]]()

    while count > 0:
        var it = _first
        var step = count // 2
        it += step

        if it[] <= value:
            it += 1
            _first = it
            count -= step + 1
        else:
            count = step

    return _first


fn binary_find[
    T: DType, //
](
    first: UnsafePointer[Scalar[T]],
    last: UnsafePointer[Scalar[T]],
    ref value: Scalar[T],
) -> UnsafePointer[Scalar[T]]:
    var _first = first
    _first = lower_bound(_first, last, value)

    if (_first != last) and (value >= _first[]):
        return _first
    return last
