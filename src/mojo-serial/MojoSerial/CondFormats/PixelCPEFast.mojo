from memory import UnsafePointer
from sys import sizeof
from os import PathLike

from MojoSerial.CondFormats.PixelCPEforGPU import (
    CommonParams,
    DetParams,
    ParamsOnGPU,
    LayerGeometry,
    AverageGeometry,
)
from MojoSerial.MojoBridge.DTypes import Float, Typeable

alias micronsToCm: Float = 1.0e-4


struct PixelCPEFast(Defaultable, Movable, Typeable):
    var m_detParamsGPU: List[DetParams]
    var m_commonParamsGPU: CommonParams
    var m_layerGeometry: LayerGeometry
    var m_averageGeometry: AverageGeometry

    var _cpuData: ParamsOnGPU

    @always_inline
    fn __init__(out self):
        self.m_commonParamsGPU = CommonParams()
        self.m_detParamsGPU = []
        self.m_layerGeometry = LayerGeometry()
        self.m_averageGeometry = AverageGeometry()

        self._cpuData = ParamsOnGPU(
            UnsafePointer(to=self.m_commonParamsGPU),
            self.m_detParamsGPU.unsafe_ptr(),
            UnsafePointer(to=self.m_layerGeometry),
            UnsafePointer(to=self.m_averageGeometry),
        )

    fn __init__[T: PathLike, //](out self, path: T) raises:
        self.m_commonParamsGPU = CommonParams()
        self.m_layerGeometry = LayerGeometry()
        self.m_averageGeometry = AverageGeometry()

        # TODO: Check if this works
        with open(path, "r") as file:
            rebind[UnsafePointer[CommonParams]](
                file.read_bytes(sizeof[CommonParams]()).unsafe_ptr()
            ).move_pointee_into(UnsafePointer(to=self.m_commonParamsGPU))

            # Mojo UInt is 64-bit, so we have to explicitly
            # state 32-bit for compatibility with the read file
            var ndetbyteArray = InlineArray[UInt8, DType.uint32.sizeof()](0)
            var ndetbyteList = file.read_bytes(DType.uint32.sizeof())

            @parameter
            for i in range(DType.uint32.sizeof()):
                ndetbyteArray[i] = ndetbyteList[i]

            var ndetParams: UInt32 = Scalar[DType.uint32].from_bytes(
                ndetbyteArray
            )
            self.m_detParamsGPU = List[DetParams](capacity=Int(ndetParams))
            
            var _rawDataDet = file.read_bytes(
                Int(ndetParams) * sizeof[DetParams]()
            )
            for i in range(Int(ndetParams)):
                rebind[UnsafePointer[DetParams]](
                    _rawDataDet.unsafe_ptr() + i
                ).move_pointee_into(self.m_detParamsGPU.unsafe_ptr() + i)

            rebind[UnsafePointer[AverageGeometry]](
                file.read_bytes(sizeof[AverageGeometry]()).unsafe_ptr()
            ).move_pointee_into(UnsafePointer(to=self.m_averageGeometry))
            rebind[UnsafePointer[LayerGeometry]](
                file.read_bytes(sizeof[LayerGeometry]()).unsafe_ptr()
            ).move_pointee_into(UnsafePointer(to=self.m_layerGeometry))

        self._cpuData = ParamsOnGPU(
            UnsafePointer(to=self.m_commonParamsGPU),
            self.m_detParamsGPU.unsafe_ptr(),
            UnsafePointer(to=self.m_layerGeometry),
            UnsafePointer(to=self.m_averageGeometry),
        )

    @always_inline
    fn getCPUProduct(self) -> ParamsOnGPU:
        return self._cpuData

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "PixelCPEFast"
