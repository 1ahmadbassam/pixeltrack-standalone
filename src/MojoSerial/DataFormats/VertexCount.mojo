@fieldwise_init
@register_passable("trivial")
struct VertexCount(Movable, Copyable):
    var _verticies: UInt

    @always_inline
    fn nVerticies(self) -> UInt:
        return self._verticies
