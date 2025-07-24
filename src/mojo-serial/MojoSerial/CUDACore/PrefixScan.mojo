from MojoSerial.CUDACore.CudaCompat import CudaCompat
from memory import UnsafePointer


fn blockPrefixScan[
    VT: DType
](ci: UnsafePointer[Scalar[VT]], co: UnsafePointer[Scalar[VT]], size: Int):
    co[0] = ci[0]
    for i in range(1, size):
        co[i] = ci[i] + co[i - 1]

fn blockPrefixScan[
    VT: DType
](c: UnsafePointer[Scalar[VT]], size: Int):
    for i in range(1, size):
        c[i] = c[i - 1]