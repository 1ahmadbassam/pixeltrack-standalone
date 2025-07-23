from MojoSerial.DataFormats.FEDRawData import FEDRawData
from MojoSerial.DataFormats.FEDNumbering import FEDNumbering

struct FEDRawDataCollection:
    var _data: List[FEDRawData]

    fn __init__(out self):
        last_id = FEDNumbering.lastFEDId()
        self._data = List[FEDRawData](capacity = last_id + 1)

    fn __copyinit__(out self, other: Self):
        self._data = other._data

    # fn FEDData(mut self, fedid: Int) -> ref [self._data] FEDRawData:
    #     return self._data[fedid]

    # fn FEDData(self, fedid: Int) -> ref [self._data] FEDRawData:
    #     return self._data[fedid]
    
    fn FEDData(ref self, fedid: Int) -> ref [self._data] FEDRawData:
        return self._data[fedid]

    fn swap(mut self, mut other: Self):
        self._data, other._data = other._data, self._data

fn swap(mut a: FEDRawDataCollection, mut b: FEDRawDataCollection):
    a.swap(b)