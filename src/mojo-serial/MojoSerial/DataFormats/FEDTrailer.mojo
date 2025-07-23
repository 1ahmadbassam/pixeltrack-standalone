from memory import UnsafePointer
from sys.info import sizeof

@fieldwise_init
@register_passable("trivial")
struct FedtStruct(Movable, Copyable):
    var conscheck: UInt32
    var eventsize: UInt32
alias FedtType = FedtStruct

alias FED_SLINK_END_MARKER = 0xa

alias FED_TCTRLID_WIDTH = 0x0000000f
alias FED_TCTRLID_SHIFT = 28
alias FED_TCTRLID_MASK = (FED_TCTRLID_WIDTH << FED_TCTRLID_SHIFT)
@always_inline
fn FED_TCTRLID_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_TCTRLID_SHIFT) & FED_TCTRLID_WIDTH)

alias FED_EVSZ_WIDTH = 0x00ffffff
alias FED_EVSZ_SHIFT = 0
alias FED_EVSZ_MASK = (FED_EVSZ_WIDTH << FED_EVSZ_SHIFT)
@always_inline
fn FED_EVSZ_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_EVSZ_SHIFT) & FED_EVSZ_WIDTH)

alias FED_CRCS_WIDTH = 0x0000ffff
alias FED_CRCS_SHIFT = 16
alias FED_CRCS_MASK = (FED_CRCS_WIDTH << FED_CRCS_SHIFT)
@always_inline
fn FED_CRCS_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_CRCS_SHIFT) & FED_CRCS_WIDTH)

alias FED_STAT_WIDTH = 0x0000000f
alias FED_STAT_SHIFT = 8
alias FED_STAT_MASK = (FED_STAT_WIDTH << FED_STAT_SHIFT)
@always_inline
fn FED_STAT_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_STAT_SHIFT) & FED_STAT_WIDTH)

alias FED_TTSI_WIDTH = 0x0000000f
alias FED_TTSI_SHIFT = 4
alias FED_TTSI_MASK = (FED_TTSI_WIDTH << FED_TTSI_SHIFT)
@always_inline
fn FED_TTSI_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_TTSI_SHIFT) & FED_TTSI_WIDTH)

alias FED_MORE_TRAILERS_WIDTH = 0x00000001
alias FED_MORE_TRAILERS_SHIFT = 3
alias FED_MORE_TRAILERS_MASK = (FED_MORE_TRAILERS_WIDTH << FED_MORE_TRAILERS_SHIFT)
@always_inline
fn FED_MORE_TRAILERS_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_MORE_TRAILERS_SHIFT) & FED_MORE_TRAILERS_WIDTH)

alias FED_CRC_MODIFIED_WIDTH = 0x00000001
alias FED_CRC_MODIFIED_SHIFT = 2
alias FED_CRC_MODIFIED_MASK = (FED_CRC_MODIFIED_WIDTH << FED_CRC_MODIFIED_SHIFT)
@always_inline
fn FED_CRC_MODIFIED_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_CRC_MODIFIED_SHIFT) & FED_CRC_MODIFIED_WIDTH)

alias FED_SLINK_ERROR_WIDTH = 0x00000001
alias FED_SLINK_ERROR_SHIFT = 14
alias FED_SLINK_ERROR_MASK = (FED_SLINK_ERROR_WIDTH << FED_SLINK_ERROR_SHIFT)
@always_inline
fn FED_SLINK_ERROR_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_SLINK_ERROR_SHIFT) & FED_SLINK_ERROR_WIDTH)

alias FED_WRONG_FEDID_WIDTH = 0x00000001
alias FED_WRONG_FEDID_SHIFT = 15
alias FED_WRONG_FEDID_MASK = (FED_WRONG_FEDID_WIDTH << FED_WRONG_FEDID_SHIFT)
@always_inline
fn FED_WRONG_FEDID_EXTRACT(a: Int) -> Int: 
    return (((a) >> FED_WRONG_FEDID_SHIFT) & FED_WRONG_FEDID_WIDTH)
fn bytes_to_u32(ptr: UnsafePointer[UInt8]) -> UInt32:
        return (UInt32(ptr[0]) << 24|
                UInt32(ptr[1]) << 16 |
                UInt32(ptr[2]) << 8|
                UInt32(ptr[3]) )
@fieldwise_init
struct FEDTrailer(Movable, Copyable):
    var _theTrailer: UnsafePointer[FedtType]
    alias length: UInt32 = sizeof[FedtType]()
    

    fn __init__(out self, ptr: UnsafePointer[UInt8]):
        
       

        conscheck = bytes_to_u32(ptr)
        eventsize = bytes_to_u32(ptr + 4)

        self._theTrailer = UnsafePointer(to=FedtStruct(conscheck, eventsize))

    #fn __init__(out self, trailer: UnsafePointer[UInt8]):
    #   self._theTrailer = trailer.bitcast[FedtType]()
        
    fn __copyinit__(out self, other: Self):
        self._theTrailer = other._theTrailer    

    fn __moveinit__(out self, owned existing: Self):
        self._theTrailer = existing._theTrailer

    fn fragmentLength(self) -> UInt32:
        return UInt32(FED_CRCS_EXTRACT(Int(self._theTrailer[].eventsize)))
    
    fn crc(self) -> UInt16:
        return UInt16(FED_CRCS_EXTRACT(Int(self._theTrailer[].conscheck)))

    fn evtStatus(self) -> UInt8:
        return UInt8(FED_STAT_EXTRACT(Int(self._theTrailer[].conscheck)))

    fn ttsBits(self) -> UInt8:
        return UInt8(FED_TTSI_EXTRACT(Int(self._theTrailer[].conscheck)))
    fn moreTrailers(self) -> Bool:
        return Bool(FED_MORE_TRAILERS_EXTRACT(Int(self._theTrailer[].conscheck)))

    fn crcModified(self) -> Bool:
        return Bool(FED_CRC_MODIFIED_EXTRACT(Int(self._theTrailer[].conscheck)))

    fn slinkError(self) -> Bool:
        return Bool(FED_SLINK_ERROR_EXTRACT(Int(self._theTrailer[].conscheck)))

    fn wrongFedId(self) -> Bool:
        return Bool(FED_WRONG_FEDID_EXTRACT(Int(self._theTrailer[].conscheck)))

    fn check(self) -> Bool:
        return Bool(FED_TCTRLID_EXTRACT(Int(self._theTrailer[].eventsize)) == FED_SLINK_END_MARKER)

    fn conscheck(self) -> UInt32:
        return self._theTrailer[].conscheck
fn main():
  
    var bytes: List[UInt8] = List[UInt8]([0xCA, 0xFE, 0xBA, 0xBE, 0xDE, 0xAA, 0xBE, 0xEF])

    trailer_ptr = UnsafePointer(to=bytes[0]) 
    trailer = FEDTrailer(trailer_ptr)
    print("Trailer Length: ", trailer.length)
    print(trailer._theTrailer[].conscheck)
    print(trailer._theTrailer[].eventsize)
    #val = 0xCAFEBABE
    #val = 0xEBABEFAC
    #val = 0xACEFABEB
    val = 0xBEBAFECA
    print(val)