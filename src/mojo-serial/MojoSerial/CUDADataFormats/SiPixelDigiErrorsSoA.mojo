from MojoSerial.CUDACore.SimpleVector import SimpleVector, make_SimpleVector
from MojoSerial.DataFormats.PixelErrors import (
    PixelErrorCompact,
    PixelFormatterErrors,
)
from MojoSerial.MojoBridge.DTypes import SizeType, Typeable


struct SiPixelDigiErrorsSoA(Defaultable, Movable, Typeable):
    alias _error_dtype = SimpleVector[
        PixelErrorCompact, PixelErrorCompact.dtype()
    ]
    var data_d: List[PixelErrorCompact]
    var error_d: Self._error_dtype
    var formatterErrors_h: PixelFormatterErrors

    @always_inline
    fn __init__(out self):
        self.data_d = []
        self.error_d = Self._error_dtype()
        self.formatterErrors_h = PixelFormatterErrors()

    @always_inline
    fn __init__(
        out self, maxFedWords: SizeType, var errors: PixelFormatterErrors
    ):
        self.formatterErrors_h = errors^
        debug_assert(maxFedWords > 0)
        self.data_d = List[PixelErrorCompact](capacity=UInt(maxFedWords))
        self.error_d = make_SimpleVector[
            PixelErrorCompact, PixelErrorCompact.dtype()
        ](UInt(maxFedWords), self.data_d.unsafe_ptr())
        debug_assert(self.error_d.empty())
        debug_assert(self.error_d.capacity() == UInt(maxFedWords))

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self.data_d = other.data_d^
        self.error_d = other.error_d^
        self.formatterErrors_h = other.formatterErrors_h^

    fn formatterErrors(self) -> PixelFormatterErrors:
        return self.formatterErrors_h

    fn error[
        origin: Origin, //
    ](ref [origin]self) -> UnsafePointer[
        Self._error_dtype, mut = origin.mut, origin=origin
    ]:
        return UnsafePointer(to=self.error_d)

    fn c_error(self) -> UnsafePointer[Self._error_dtype, mut=False]:
        return UnsafePointer(to=self.error_d)

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelDigiErrorsSoA"
