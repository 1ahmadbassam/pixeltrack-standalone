from MojoSerial.MojoBridge.DTypes import Typeable

@fieldwise_init
struct SiPixelFedIds(Copyable, Defaultable, Movable, Typeable):
    var _fedIds: List[UInt]

    fn __init__(out self):
        self._fedIds = []

    fn fedIds(self) -> ref [self._fedIds] List[UInt]:
        return self._fedIds

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelFedIds"
