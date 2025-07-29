from memory import UnsafePointer


@nonmaterializable(NoneType)
struct GPUClustering:
    @staticmethod
    fn countModules(
        id: UnsafePointer[UInt16],
        moduleStart: UnsafePointer[UInt32, mut=True],
        clusterId: UnsafePointer[Int32, mut=True],
        numElements: UInt32,
    ):
        pass

    @staticmethod
    fn findClus(
        id: UnsafePointer[UInt16],
        x: UnsafePointer[UInt16],
        y: UnsafePointer[UInt16],
        moduleStart: UnsafePointer[UInt32],
        nClustersInModule: UnsafePointer[UInt32, mut=True],
        moduleId: UnsafePointer[UInt32, mut=True],
        clusterId: UnsafePointer[Int32, mut=True],
        numElements: UInt32,
    ):
        pass

    @staticmethod
    fn clusterChargeCut(
        id: UnsafePointer[UInt16],
        adc: UnsafePointer[UInt16],
        moduleStart: UnsafePointer[UInt32],
        nClustersInModule: UnsafePointer[UInt32, mut=True],
        moduleId: UnsafePointer[UInt32],
        clusterId: UnsafePointer[Int32, mut=True],
        numElements: UInt32,
    ):
        pass
