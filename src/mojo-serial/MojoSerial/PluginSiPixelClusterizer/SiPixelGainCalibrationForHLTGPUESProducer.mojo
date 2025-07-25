from pathlib import Path

from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
struct SiPixelGainCalibrationForHLTGPUESProducer(
    Defaultable, ESProducer, Movable, Typeable
):
    var _data: Path

    @always_inline
    fn __init__(out self):
        self._data = Path("")

    fn produce(mut self, ref eventSetup: EventSetup):
        try:
            with open(self._data / "gain.bin", 'r') as file:
                # TODO: Continue from here
                pass
        except e:
            print("Error during loading data in SiPixelGainCalibrationForHLTGPUESProducer:", e)

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelGainCalibrationForHLTGPUESProducer"
