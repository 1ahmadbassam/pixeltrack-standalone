@nonmaterializable(NoneType)
struct GPUClusteringConstants:
    alias maxNumberOfHits: UInt32 = 48 * 1024

    @staticmethod
    @always_inline
    fn maxHitsInIter() -> UInt32:
        return 160

    @staticmethod
    @always_inline
    fn maxHitsInModule() -> UInt32:
        return 1024

    alias MaxNumModules: UInt32 = 2000
    alias MaxNumClustersPerModules: Int32 = Self.maxHitsInModule().cast[
        DType.int32
    ]()
    alias MaxHitsInModule: UInt32 = Self.maxHitsInModule()
    alias MaxNumClusters: UInt32 = Self.maxNumberOfHits
    alias InvId: UInt16 = 9999
