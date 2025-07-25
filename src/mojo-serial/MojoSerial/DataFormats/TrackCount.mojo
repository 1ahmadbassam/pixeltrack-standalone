from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
@register_passable("trivial")
struct TrackCount(Copyable, Defaultable, Movable, Typeable):
    var _tracks: Int

    @always_inline
    fn __init__(out self):
        self._tracks = 0

    @always_inline
    fn n_tracks(self) -> Int:
        return self._tracks

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "TrackCount"
