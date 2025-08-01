from memory import UnsafePointer
from sys import sizeof
import os


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
    return file.read_bytes(sizeof[T]()).data.bitcast[T]().take_pointee()


@always_inline
fn read_aligned_obj[
    T: Movable, *FieldTypes: AnyType
](mut file: FileHandle, align: Int, *fake_fields: *FieldTypes) raises -> T:
    var ptr = UnsafePointer[T].alloc(1)
    var byte_ptr = ptr.bitcast[UInt8]()

    var offset = 0

    @parameter
    for i in range(fake_fields.__len__()):
        alias field_type = __type_of(fake_fields[i])
        alias field_size = sizeof[field_type]()

        file.read_bytes(field_size).data.move_pointee_into(byte_ptr)

        byte_ptr += field_size
        offset += field_size

        var remainder = offset % align
        if remainder != 0:
            var padding_to_skip = align - remainder
            _ = file.seek(padding_to_skip, os.SEEK_CUR)
            offset += padding_to_skip

    return ptr.take_pointee()


@always_inline
fn read_list[
    T: Movable & Copyable
](mut file: FileHandle, owned num: Int) raises -> List[T]:
    var ret = List[T](unsafe_uninit_length=num)
    var elements = file.read_bytes(num * sizeof[T]())
    var data = elements.data.bitcast[T]()
    for i in range(num):
        (data + i).move_pointee_into(ret.data + i)
    return ret^
