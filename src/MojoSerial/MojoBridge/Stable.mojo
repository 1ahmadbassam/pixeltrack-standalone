from memory import UnsafePointer

# This file and its usages are to be reviewed on every update 
# to the Mojo language. Our goal is to target the latest stable
# version while introducing (much needed) improvements from nightly
# versions.

alias OpaquePointer = UnsafePointer[NoneType]
alias NonePointer = OpaquePointer()

trait IteratorTrait(Movable):
    """
    The `IteratorTrait` trait describes a type that can be used as an
    iterator, e.g. in a `for` loop.
    """
    alias Element: AnyType

    fn __has_next__(self) -> Bool:
        ...

    fn __next__(mut self) -> Element:
        ...

alias Iterator = IteratorTrait