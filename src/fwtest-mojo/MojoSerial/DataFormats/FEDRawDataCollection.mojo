from MojoSerial.DataFormats.FEDRawData import FEDRawData
from MojoSerial.DataFormats.FEDNumbering import FEDNumbering
from MojoSerial.MojoBridge.DTypes import Typeable


struct FEDRawDataCollection(Copyable, Defaultable, Movable, Typeable):
    var _data: List[FEDRawData]

    @always_inline
    fn __init__(out self):
        self._data = List[FEDRawData](capacity=FEDNumbering.lastFEDId() + 1)

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._data = other._data^

    @always_inline
    fn __copyinit__(out self, other: Self):
        self._data = other._data

    @always_inline
    fn FEDData(ref self, fedid: Int) -> ref [self._data] FEDRawData:
        return self._data[fedid]

    @always_inline
    fn swap(mut self, mut other: Self):
        self._data, other._data = other._data, self._data

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "FEDRawDataCollection"


@always_inline
fn swap(mut a: FEDRawDataCollection, mut b: FEDRawDataCollection):
    a.swap(b)
