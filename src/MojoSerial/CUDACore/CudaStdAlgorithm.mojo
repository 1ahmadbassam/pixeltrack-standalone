fn lower_bound[T: Movable & Copyable & Comparable](ref first: Int, ref last: Int, ref val: T, L: List[T]) -> Int:
    var _first = first
    var count = last - _first

    while count > 0:
        var it = _first
        var step = count // 2
        it += step
        if L[it] < val:
            _first = it + 1
            count -= step + 1
        else:
            count = step
    return _first

fn upper_bound[T: Movable & Copyable & Comparable](ref first: Int, ref last: Int, ref val: T, L: List[T]) -> Int:
    var _first = first
    var count = last - _first

    while count > 0:
        var it = _first
        var step = count // 2
        it += step
        if val < L[it]:
            _first = it + 1
            count -= step + 1
        else:
            count = step
    return _first

fn binary_find[T: Movable & Copyable & Comparable](ref first: Int, ref last: Int, ref val: T, L: List[T]) -> Int:
    var _first = lower_bound(first, last, val, L)
    return _first if _first != last and not val < L[_first] else -1
