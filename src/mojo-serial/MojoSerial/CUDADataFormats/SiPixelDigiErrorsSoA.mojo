from memory import UnsafePointer, OwnedPointer

from MojoSerial.CUDACore.SimpleVector import SimpleVector, make_SimpleVector
from MojoSerial.DataFormats.PixelErrors import (
    PixelErrorCompact,
    PixelFormatterErrors,
)
from MojoSerial.MojoBridge.DTypes import SizeType


struct SiPixelDigiErrorsSoA(Defaultable, Movable):
    var data_d: List[PixelErrorCompact]
    var error_d: SimpleVector[PixelErrorCompact]
    var formatterErrors_h: PixelFormatterErrors

    @always_inline
    fn __init__(out self):
        self.data_d = []
        self.error_d = SimpleVector[PixelErrorCompact]()
        self.formatterErrors_h = PixelFormatterErrors()

    @always_inline
    fn __init__(
        out self, maxFedWords: SizeType, owned errors: PixelFormatterErrors
    ):
        self.formatterErrors_h = errors^
        self.data_d = List[PixelErrorCompact](capacity=maxFedWords)
        self.error_d = make_SimpleVector(maxFedWords, self.data_d.unsafe_ptr())
        debug_assert(self.error_d.empty())
        debug_assert(self.error_d.capacity() == maxFedWords)

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self.data_d = other.data_d^
        self.error_d = other.error_d^
        self.formatterErrors_h = other.formatterErrors_h^

    fn formatterErrors(self) -> PixelFormatterErrors:
        return self.formatterErrors_h

    fn error[
        is_mutable: Bool, //, origin: Origin[is_mutable]
    ](ref [origin]self) -> UnsafePointer[SimpleVector[PixelErrorCompact]]:
        return UnsafePointer(to=self.error_d)

    fn c_error(self) -> UnsafePointer[SimpleVector[PixelErrorCompact]]:
        return UnsafePointer(to=self.error_d)
