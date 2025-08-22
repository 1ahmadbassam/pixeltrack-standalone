from pathlib import Path
from sys.info import sizeof
from memory import memcpy

from MojoSerial.DataFormats.BeamSpotPOD import BeamSpotPOD
from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.MojoBridge.DTypes import Typeable, TypeableOwnedPointer


struct BeamSpotESProducer(Defaultable, ESProducer, Movable, Typeable):
    var _data: Path

    @always_inline
    fn __init__(out self):
        self._data = Path("")

    @always_inline
    fn __init__(out self, var path: Path):
        self._data = path^

    @always_inline
    fn produce(mut self, mut eventSetup: EventSetup):
        var bs = TypeableOwnedPointer(BeamSpotPOD())
        try:
            with open(self._data / "beamspot.bin", "r") as f:
                bs._ptr[] = rebind[BeamSpotPOD](f.read_bytes())
            eventSetup.put[TypeableOwnedPointer[BeamSpotPOD]](bs^)
        except e:
            print(
                "Error during loading data in BeamSpotESProducer:",
                e,
            )

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "BeamSpotESProducer"
