from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
@register_passable("trivial")
struct VertexCount(Copyable, Movable, Typeable):
    var _vertcies: UInt

    @always_inline
    fn nVertcies(self) -> UInt:
        return self._vertcies

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "VertexCount"
