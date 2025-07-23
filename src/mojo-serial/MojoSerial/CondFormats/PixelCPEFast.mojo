#from MojoSerial.Geometry import phase1PixelTopology
from CondFormats.pixelCPEforGPU import CommonParams, DetParams, ParamsOnGPU, LayerGeometry, AverageGeometry
from sys.info import sizeof
import os
struct PixelCPEFast:
    var m_commonParamsGPU: CommonParams
    var m_detParamsGPU: List[DetParams]
    var m_layerGeometry: LayerGeometry
    var m_averageGeometry: AverageGeometry
    var cpuData_: ParamsOnGPU

    fn __init__(out self, path: StringSlice) raises:
        with open(path, "r") as file:
            var common_params_bytes = file.read_bytes(sizeof[CommonParams]())
            for i in range(0, 16, 4):
                var byte_array = InlineArray[SIMD[DType.uint8, 1], DType.float32.sizeof()](common_params_bytes[i],
                    common_params_bytes[i+1],
                    common_params_bytes[i+2],
                    common_params_bytes[i+3]
                )
                var value = SIMD[DType.float32, 1].from_bytes(byte_array)
                if i == 0:
                    self.m_commonParamsGPU.theThicknessB = value
                elif i == 4:
                    self.m_commonParamsGPU.theThicknessE = value
                elif i == 8:
                    self.m_commonParamsGPU.thePitchX = value
                elif i == 12:
                    self.m_commonParamsGPU.thePitchY = value

            
            var ndet_params_bytes = file.read_bytes(sizeof[UInt32]())
            var byte_array_ndet = InlineArray[SIMD[DType.uint8, 1], DType.uint32.sizeof()](ndet_params_bytes[0],
                ndet_params_bytes[1],
                ndet_params_bytes[2],
                ndet_params_bytes[3]
            )
            var ndetParams = SIMD[DType.uint32, 1].from_bytes(byte_array_ndet)
            self.m_detParamsGPU = List[DetParams]()
            total_bytes = ndetParams * sizeof[DetParams]()
            var det_params_bytes = file.read_bytes(Int(total_bytes))
            
            for i in range()











































































            # Read m_detParamsGPU
            # TODO: Use ndetParams value
            var det_params_bytes = file.read_bytes(ndetParams * sizeof[pixelCPEforGPU::DetParams]())
            # TODO: Deserialize to List[pixelCPEforGPU::DetParams]
            # e.g., m_detParamsGPU = deserialize_DetParams(det_params_bytes, ndetParams)

            # Read m_averageGeometry
            var avg_geom_bytes = file.read_bytes(sizeof[pixelCPEforGPU::AverageGeometry]())
            # TODO: Convert to pixelCPEforGPU::AverageGeometry

            # Read m_layerGeometry
            var layer_geom_bytes = file.read_bytes(sizeof[pixelCPEforGPU::LayerGeometry]())
            # TODO: Convert to pixelCPEforGPU::LayerGeometry

        # Assign to cpuData_
        cpuData_ = {
            &m_commonParamsGPU,
            m_detParamsGPU.data(),
            &m_layerGeometry,
            &m_averageGeometry
        }
