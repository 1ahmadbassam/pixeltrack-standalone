from memory import UnsafePointer
from pathlib import Path

from MojoSerial.CondFormats.SiPixelGainForHLTonGPU import SiPixelGainForHLTonGPU
from MojoSerial.CondFormats.SiPixelGainCalibrationForHLTGPU import (
    SiPixelGainCalibrationForHLTGPU,
)
from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.MojoBridge.DTypes import Char, Typeable
from MojoSerial.MojoBridge.File import read_simd, read_obj


@fieldwise_init
struct SiPixelGainCalibrationForHLTGPUESProducer(
    Defaultable, ESProducer, Movable, Typeable
):
    var _data: Path

    @always_inline
    fn __init__(out self):
        self._data = Path("")

    fn produce(mut self, mut eventSetup: EventSetup):
        try:
            with open(self._data / "gain.bin", "r") as file:
                var gain = read_obj[SiPixelGainForHLTonGPU](file)
                var nbytes = read_simd[DType.uint32](file)
                var gainData = file.read_bytes(Int(nbytes))
                eventSetup.put[SiPixelGainCalibrationForHLTGPU](
                    SiPixelGainCalibrationForHLTGPU(
                        gain^, rebind[List[Char]](gainData^)
                        # rebind works because UInt8 and Int8 are bit-compatible
                    )
                )
        except e:
            print(
                (
                    "Error during loading data in"
                    " SiPixelGainCalibrationForHLTGPUESProducer:"
                ),
                e,
            )

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelGainCalibrationForHLTGPUESProducer"


# TODO-PLG: DEFINE_FWK_EVENTSETUP_MODULE
