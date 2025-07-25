from memory import UnsafePointer

from MojoSerial.MojoBridge.DTypes import SizeType, Typeable


struct FEDRawData(Copyable, Defaultable, Movable, Typeable):
    """
    Class representing the raw data for one FED.
    The raw data is owned as a binary buffer. It is required that the
    length of the data is a multiple of the S-Link64 word length (8 byte).
    The FED data should include the standard FED header and trailer.
    """

    alias Data = List[UInt8]
    var _data: Self.Data

    @always_inline
    fn __init__(out self):
        self._data = []

    @always_inline
    fn __init__(out self, newsize: Int):
        debug_assert(
            newsize % 8 == 0,
            "Size " + String(newsize) + " is not a multiple of 8 bytes.",
        )

        self._data = Self.Data(length=newsize, fill=0)

    @always_inline
    fn __copyinit__(out self, existing: Self):
        self._data = existing._data

    @always_inline
    fn __moveinit__(out self, owned existing: Self):
        self._data = existing._data^

    @always_inline
    fn data[
        origin: Origin, //
    ](ref [origin]self) -> UnsafePointer[
        UInt8, mut = origin.mut, origin=origin
    ]:
        return self._data.unsafe_ptr()

    @always_inline
    fn size(self) -> SizeType:
        return self._data.__len__()

    @always_inline
    fn resize(mut self, newsize: SizeType):
        debug_assert(
            newsize % 8 == 0,
            "Size " + String(newsize) + " is not a multiple of 8 bytes.",
        )

        if self.size() == newsize:
            return

        self._data.resize(newsize, 0)

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "FEDRawData"
