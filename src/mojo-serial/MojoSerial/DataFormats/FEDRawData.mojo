from MojoSerial.MojoBridge.DTypes import SizeType
from memory import UnsafePointer

struct FEDRawData(Copyable, Movable):
    var _data: List[UInt8]

    fn __init__(out self):
        self._data = []

    fn __init__(out self, newsize: Int) raises:
        debug_assert(newsize % 8 == 0, "Size" + String(newsize) + "is not a multiple of 8")

        self._data : List[UInt8] = List[UInt8](length = newsize, fill = 0)

    fn __copyinit__(out self, existing: Self):
        self._data = existing._data

    fn __moveinit__(out self, owned existing: Self):
        self._data = existing._data^

    fn data(ref self) -> UnsafePointer[UInt8]:
        return UnsafePointer(to = self._data[0])

    fn size(self) -> SizeType:
        return len(self._data)

    fn resize(mut self, newsize: SizeType) raises:
        debug_assert(newsize % 8 == 0, "Size" + String(newsize) + "is not a multiple of 8")

        current_size = len(self._data)
        if current_size == newsize:
            return
            
        new_list = List[UInt8](length = newsize, fill = 0)

        for i in range(min(current_size,current_size)):
            new_list[i] = self._data[i]

        self._data = new_list^