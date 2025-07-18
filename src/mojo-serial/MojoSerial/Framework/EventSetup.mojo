trait ESWrapperBase:
    pass

struct ESWrapper[T: Movable](ESWrapperBase):
    var _obj: T

    fn __init__(out self, owned obj: T):
        self._obj = obj^

    fn product(self) -> ref [self._obj] T:
        return self._obj
