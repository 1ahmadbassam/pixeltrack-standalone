from memory import UnsafePointer
from pathlib import Path
from sys import sizeof

from MojoSerial.CondFormats.SiPixelGainForHLTonGPU import SiPixelGainForHLTonGPU
from MojoSerial.CondFormats.SiPixelGainCalibrationForHLTGPU import (
    SiPixelGainCalibrationForHLTGPU,
)
from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.MojoBridge.DTypes import Char, Typeable


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
                var gain = rebind[UnsafePointer[SiPixelGainForHLTonGPU]](
                    file.read_bytes(
                        sizeof[SiPixelGainForHLTonGPU]()
                    ).unsafe_ptr()
                ).take_pointee()
                var nbytes = rebind[UnsafePointer[UInt32]](
                    file.read_bytes(DType.uint32.sizeof()).unsafe_ptr()
                ).take_pointee()
                var gainData = rebind[UnsafePointer[List[Char]]](
                    file.read_bytes(Int(nbytes)).unsafe_ptr()
                ).take_pointee()
                eventSetup.put[SiPixelGainCalibrationForHLTGPU](
                    SiPixelGainCalibrationForHLTGPU(gain^, gainData^)
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


# TODO-PLG: DEFINE_FWK_EVENTSETUP_MODULE for this file once we find a way around the plugin factory
