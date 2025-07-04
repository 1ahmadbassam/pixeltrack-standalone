from memory import UnsafePointer

from MojoSerial.MojoBridge.DTypes import OpaquePointer, NonePointer

alias CudaStreamType = OpaquePointer
alias cudaStreamDefault: OpaquePointer = NonePointer

struct CudaCompact:
    @staticmethod
    fn atomicCAS[T1: Copyable & EqualityComparable, //](address: UnsafePointer[T1], compare: T1, val: T1) -> T1:
        var old: T1 = address[]
        address[] = val if old == compare else old
        return old

    @staticmethod
    fn atomicInc[T1: DType, //](a: UnsafePointer[Scalar[T1]], b: Scalar[T1])-> Scalar[T1]:
        var ret: Scalar[T1] = a[]
        if ret < b:
            a[]+= 1
        return ret
    
    @staticmethod
    fn atomicAdd[T1: DType, //](a: UnsafePointer[Scalar[T1]], b: Scalar[T1])-> Scalar[T1]:
        var ret: Scalar[T1] = a[]
        a[] += b
        return ret

    @staticmethod
    fn atomicSub[T1: DType, //](a: UnsafePointer[Scalar[T1]], b: Scalar[T1])-> Scalar[T1]:
        var ret: Scalar[T1] = a[]
        a[] -= b
        return ret

    @staticmethod
    fn atomicMin[T1: Copyable & Comparable, //](a: UnsafePointer[T1], b: T1)-> T1:
        var ret: T1 = a[]
        a[] = min(a[], b)
        return ret

    @staticmethod
    fn atomicMax[T1: Copyable & Comparable, //](a: UnsafePointer[T1], b: T1)-> T1:
        var ret: T1 = a[]
        a[] = max(a[], b)
        return ret

