from MojoSerial.DataFormats.SiPixelRawDataError import SiPixelRawDataError
from memory import UnsafePointer

struct ErrorChecker:

    alias Word32 = UInt32
    alias Word64 = UInt64
    alias DetErrors = List[SiPixelRawDataError]
    alias Errors = Dict[Int, Self.DetErrors]
    alias CRC_bits = 1
    alias LINK_bits = 6
    alias ROC_bits = 5
    alias DCOL_bits = 5
    alias PXID_bits = 8
    alias ADC_bits = 8
    alias OMIT_ERR_bits = 1
    alias CRC_shift = 2
    alias ADC_shift = 0
    alias PXID_shift = Self.ADC_shift + Self.ADC_bits
    alias DCOL_shift = Self.PXID_shift + Self.PXID_bits
    alias ROC_shift = Self.DCOL_shift + Self.DCOL_bits
    alias LINK_shift = Self.ROC_shift + Self.ROC_bits
    alias OMIT_ERR_shift = 20
    alias dummyDetId = 0xffffffff
    alias CRC_mask: Self.Word64  = ~(~Self.Word64(0) << Self.CRC_bits)
    alias ERROR_mask: Self.Word32 = ~(~Self.Word32(0) << Self.ROC_bits)
    alias LINK_mask: Self.Word32 = ~(~Self.Word32(0) << Self.LINK_bits)
    alias ROC_mask: Self.Word32 = ~(~Self.Word32(0) << Self.ROC_bits)
    alias OMIT_ERR_mask: Self.Word32 = ~(~Self.Word32(0) << Self.OMIT_ERR_bits)


    var includeErrors: Bool

    def __init__(out self):
        self.includeErrors = False

    def checkCRC(self, mut errorsInEvent: Bool, fedId:Int, trailer: UnsafePointer[Self.Word64], mut errors: Self.Errors) -> Bool:
        var CRC_BIT  = trailer[] >> Self.CRC_shift & Self.CRC_mask
        if CRC_BIT == 0: return True
        errorsInEvent = True
        if self.includeErrors:
            var errorType = 39
            var error = SiPixelRawDataError(
                trailer[], errorType, fedId
            )
            errors[Self.dummyDetId].append(error)


    def checkHeader(self, mut errorsInEvent: Bool, fedId:Int, header: UnsafePointer[Self.Word64], mut errors: Self.Errors) -> Bool:
        ...

    def checkTrailer(self, mut errorsInEvent: Bool, fedId:Int, nWords: UInt32, trailer: UnsafePointer[Self.Word64], mut errors: Self.Errors) -> Bool:
        ...
    