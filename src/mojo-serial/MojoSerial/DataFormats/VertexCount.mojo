@fieldwise_init
@register_passable("trivial")
struct VertexCount(Movable, Copyable):
    var _vertcies: UInt

    @always_inline
    fn nVertcies(self) -> UInt:
        return self._vertcies
