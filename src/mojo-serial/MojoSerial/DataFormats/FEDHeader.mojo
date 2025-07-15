@fieldwise_init
@register_passable("trivial")
struct FedhStruct(Movable, Copyable):
    var sourceid: UInt32
    var eventid: UInt32
alias FedhType = FedhStruct

alias FED_SLINK_START_MARKER = 0x5

alias FED_HCTRLID_WIDTH = 0x0000000f
alias FED_HCTRLID_SHIFT = 28
alias FED_HCTRLID_MASK = (FED_HCTRLID_WIDTH << FED_HCTRLID_SHIFT)
@always_inline
fn FED_HCTRLID_EXTRACT(a: Int) -> Int:
    return (((a) >> FED_HCTRLID_SHIFT) & FED_HCTRLID_WIDTH)

alias FED_EVTY_WIDTH = 0x0000000f
alias FED_EVTY_SHIFT = 24
alias FED_EVTY_MASK = (FED_EVTY_WIDTH << FED_EVTY_SHIFT)
@always_inline
fn FED_EVTY_EXTRACT(a: Int) -> Int:
    return (((a) >> FED_EVTY_SHIFT) & FED_EVTY_WIDTH)

alias FED_LVL1_WIDTH = 0x00ffffff
alias FED_LVL1_SHIFT = 0
alias FED_LVL1_MASK = (FED_LVL1_WIDTH << FED_LVL1_SHIFT)
@always_inline
fn FED_LVL1_EXTRACT(a: Int) -> Int:
    return (((a) >> FED_LVL1_SHIFT) & FED_LVL1_WIDTH)

alias FED_BXID_WIDTH = 0x00000fff
alias FED_BXID_SHIFT = 20
alias FED_BXID_MASK = (FED_BXID_WIDTH << FED_BXID_SHIFT)
@always_inline
fn FED_BXID_EXTRACT(a: Int) -> Int:
    return (((a) >> FED_BXID_SHIFT) & FED_BXID_WIDTH)

alias FED_SOID_WIDTH = 0x00000fff
alias FED_SOID_SHIFT = 8
alias FED_SOID_MASK = (FED_SOID_WIDTH << FED_SOID_SHIFT)
@always_inline
fn FED_SOID_EXTRACT(a: Int) -> Int:
    return (((a) >> FED_SOID_SHIFT) & FED_SOID_WIDTH)

alias FED_VERSION_WIDTH = 0x0000000f
alias FED_VERSION_SHIFT = 4
alias FED_VERSION_MASK = (FED_VERSION_WIDTH << FED_VERSION_SHIFT)
@always_inline
fn FED_VERSION_EXTRACT(a: Int) -> Int:
    return (((a) >> FED_VERSION_SHIFT) & FED_VERSION_WIDTH)

alias FED_MORE_HEADERS_WIDTH = 0x00000001
alias FED_MORE_HEADERS_SHIFT = 3
alias FED_MORE_HEADERS_MASK = (FED_MORE_HEADERS_WIDTH << FED_MORE_HEADERS_SHIFT)
@always_inline
fn FED_MORE_HEADERS_EXTRACT(a: Int) -> Int:
    return (((a) >> FED_MORE_HEADERS_SHIFT) & FED_MORE_HEADERS_WIDTH)
