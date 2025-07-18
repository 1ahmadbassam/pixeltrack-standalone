from MojoSerial.DataFormats.SiPixelRawDataError import SiPixelRawDataError


@fieldwise_init
@register_passable("trivial")
struct PixelErrorCompact(Copyable, Defaultable, Movable):
    var raw_id: UInt32
    var word: UInt32
    var error_type: UInt8
    var fed_id: UInt8

    @always_inline
    fn __init__(out self):
        self.raw_id = 0
        self.word = 0
        self.error_type = 0
        self.fed_id = 0


alias PixelFormatterErrors = Dict[Int, List[SiPixelRawDataError]]
