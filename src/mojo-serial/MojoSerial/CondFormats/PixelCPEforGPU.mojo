from MojoSerial.MojoBridge.DTypes import Typeable


struct ParamsOnGPU(Copyable, Movable, Typeable):
    # TODO: Replace this stub
    fn __init__(out self):
        pass

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "ParamsOnGPU"

    pass
