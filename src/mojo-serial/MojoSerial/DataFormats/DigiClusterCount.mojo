from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
@register_passable("trivial")
struct DigiClusterCount(Copyable, Defaultable, Movable, Typeable):
    var _modules: UInt
    var _digis: UInt
    var _clusters: UInt

    @always_inline
    fn __init__(out self):
        self._modules = 0
        self._digis = 0
        self._clusters = 0

    @always_inline
    fn nModules(self) -> UInt:
        return self._modules

    @always_inline
    fn nDigis(self) -> UInt:
        return self._digis

    @always_inline
    fn nClusters(self) -> UInt:
        return self._clusters

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "DigiClusterCount"
