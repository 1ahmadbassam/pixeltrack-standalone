from memory import UnsafePointer
from sys import sizeof


@always_inline
fn read_simd[T: DType](mut file: FileHandle) raises -> Scalar[T]:
    var bytes = file.read_bytes(T.sizeof())
    var array = InlineArray[UInt8, T.sizeof()](uninitialized=True)

    @parameter
    for i in range(T.sizeof()):
        array[i] = (bytes.data + i).take_pointee()
    return Scalar[T].from_bytes(array^)


@always_inline
fn read_obj[T: Movable](mut file: FileHandle) raises -> T:
    return rebind[UnsafePointer[T]](
        file.read_bytes(sizeof[T]()).unsafe_ptr()
    ).take_pointee()


@always_inline
fn read_list[
    T: Movable & Copyable
](mut file: FileHandle, owned num: Int) raises -> List[T]:
    var ret = List[T](unsafe_uninit_length=num)
    var elements = file.read_bytes(num * sizeof[T]())
    for i in range(num):
        (rebind[UnsafePointer[T]](elements.data) + i).move_pointee_into(
            ret.data + i
        )
    return ret^
