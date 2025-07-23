@fieldwise_init
@register_passable("trivial")
struct DigiClusterCount(Copyable, Movable):
    var _modules: UInt
    var _digis: UInt
    var _clusters: UInt

    fn nModules(self) -> UInt:
        return self._modules

    fn nDigis(self) -> UInt:
        return self._digis

    fn nClusters(self) -> UInt:
        return self._clusters