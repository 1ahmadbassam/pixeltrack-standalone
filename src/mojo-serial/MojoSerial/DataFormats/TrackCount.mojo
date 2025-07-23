@fieldwise_init
@register_passable("trivial")
struct TrackCount(Movable, Copyable):
    var _tracks: Int

    @always_inline
    fn n_tracks(self) -> Int:
        return self._tracks