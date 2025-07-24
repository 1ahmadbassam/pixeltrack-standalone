from MojoSerial.DataFormats.SiPixelRawDataError import SiPixelRawDataError

@fieldwise_init
struct ErrorChecker:
    var Word32: UInt32
    var Word64: UInt64
    var DetErrors: List[SiPixelRawDataError]

    