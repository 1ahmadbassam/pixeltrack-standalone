from memory import OwnedPointer, UnsafePointer
from MojoSerial.CUDACore.CudaCompat import CudaStreamType
from MojoSerial.MojoBridge.DTypes import SizeType

# in principle, a heterogenous SoA implementation regardless of device it runs on should use UnsafePointers based on Mojo's intrinsics

alias HeterogeneousSoA = OwnedPointer
alias HeterogeneousSoAImpl = OwnedPointer
alias HeterogeneousSoACPU = HeterogeneousSoAImpl


trait Traits:
    # unable to constraint pointers to pointer trait as it currently does not exist
    alias UniquePointer: AnyType


@deprecated(
    "Heterogenous unique pointers should explicitly rely on Mojo standard"
    " pointers"
)
struct CPUTraits[T: AnyType](Traits):
    alias UniquePointer = UnsafePointer[T]

    @staticmethod
    fn make_unique(x: CudaStreamType) -> Self.UniquePointer:
        return Self.UniquePointer.alloc(1)

    @staticmethod
    fn make_unique(size: SizeType, x: CudaStreamType) -> Self.UniquePointer:
        return Self.UniquePointer.alloc(size)

    @staticmethod
    fn make_host_unique(x: CudaStreamType) -> Self.UniquePointer:
        return Self.UniquePointer.alloc(1)

    @staticmethod
    fn make_device_unique(x: CudaStreamType) -> Self.UniquePointer:
        return Self.UniquePointer.alloc(1)

    @staticmethod
    fn make_device_unique(
        size: SizeType, x: CudaStreamType
    ) -> Self.UniquePointer:
        return Self.UniquePointer.alloc(size)
