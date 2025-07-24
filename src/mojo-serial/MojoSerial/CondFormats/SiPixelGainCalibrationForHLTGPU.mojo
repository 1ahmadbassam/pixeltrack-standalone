from memory import UnsafePointer

from MojoSerial.CondFormats.SiPixelGainForHLTonGPU import SiPixelGainForHLTonGPU
from MojoSerial.MojoBridge.DTypes import Char, Typeable


struct SiPixelGainCalibrationForHLTGPU(
    Copyable, Defaultable, Movable, Typeable
):
    var _gainForHLTonHost: SiPixelGainForHLTonGPU
    var _gainData: List[Char]

    @always_inline
    fn __init__(out self):
        self._gainForHLTonHost = SiPixelGainForHLTonGPU()
        self._gainData = []

    @always_inline
    fn __init__(
        out self, gain: SiPixelGainForHLTonGPU, owned gainData: List[Char]
    ):
        self._gainData = gainData^
        self._gainForHLTonHost = gain
        self._gainForHLTonHost.v_pedestals = rebind[
            UnsafePointer[SiPixelGainForHLTonGPU.DecodingStructure]
        ](self._gainData.unsafe_ptr())

    @always_inline
    fn getCPUProduct(self) -> UnsafePointer[SiPixelGainForHLTonGPU, mut=False]:
        return UnsafePointer(to=self._gainForHLTonHost)

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelGainCalibrationForHLTGPU"
