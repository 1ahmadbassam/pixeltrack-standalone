from memory import UnsafePointer

struct TKRotation[U:DType]:
    pass

struct SOARotation[T:DType](Movable, Copyable):
    var R11: Scalar[T]
    var R12: Scalar[T]
    var R13: Scalar[T]
    var R21: Scalar[T]
    var R22: Scalar[T]
    var R23: Scalar[T]
    var R31: Scalar[T]
    var R32: Scalar[T]
    var R33: Scalar[T]

    fn __init__(out self):
        self.R11 = 1; self.R12 = 0; self.R13 = 0
        self.R21 = 0; self.R22 = 1; self.R23 = 0
        self.R31 = 0; self.R32 = 0; self.R33 = 1

    fn __copyinit__(out self, other: Self):
        self.R11 = other.R11; self.R12 = other.R12; self.R13 = other.R13
        self.R21 = other.R21; self.R22 = other.R22; self.R23 = other.R23
        self.R31 = other.R31; self.R32 = other.R32; self.R33 = other.R33

    fn __moveinit__(out self, owned other: Self):
        self.R11 = other.R11; self.R12 = other.R12; self.R13 = other.R13
        self.R21 = other.R21; self.R22 = other.R22; self.R23 = other.R23
        self.R31 = other.R31; self.R32 = other.R32; self.R33 = other.R33

    fn __init__(out self,
                        xx: Scalar[T], xy: Scalar[T], xz: Scalar[T],
                        yx: Scalar[T], yy: Scalar[T], yz: Scalar[T],
                        zx: Scalar[T], zy: Scalar[T], zz: Scalar[T]):
        self.R11 = xx; self.R12 = xy; self.R13 = xz
        self.R21 = yx; self.R22 = yy; self.R23 = yz
        self.R31 = zx; self.R32 = zy; self.R33 = zz

    fn __init__(out self, p: UnsafePointer[Scalar[T]]):

        self.R11 = p[0]; self.R12 = p[1]; self.R13 = p[2]
        self.R21 = p[3]; self.R22 = p[4]; self.R23 = p[5]
        self.R31 = p[6]; self.R32 = p[7]; self.R33 = p[8]

    # fn __init__ (out self, a: TKRotation[U]): 
    #     self.R11 = a.xx()
    #     self.R12 = a.xy()
    #     self.R13 = a.xz()
    #     self.R21 = a.yx()
    #     self.R22 = a.yy()
    #     self.R23 = a.yz()
    #     self.R31 = a.zx()
    #     self.R32 = a.zy()
    #     self.R33 = a.zz()

    @always_inline
    fn transposed(self) -> Self:
        return Self(self.R11, self.R21, self.R31,
                    self.R12, self.R22, self.R32,
                    self.R13, self.R23, self.R33)

    @always_inline
    fn multiply(self, vx: SIMD[T,1], vy: SIMD[T,1], vz: SIMD[T,1], mut ux: SIMD[T,1], mut uy: SIMD[T,1], mut uz: SIMD[T,1]):
        ux = self.R11 * vx + self.R12 * vy + self.R13 * vz
        uy = self.R21 * vx + self.R22 * vy + self.R23 * vz
        uz = self.R31 * vx + self.R32 * vy + self.R33 * vz

    @always_inline
    fn multiplyInverse(self, vx: SIMD[T,1], vy: SIMD[T,1], vz: SIMD[T,1], mut ux: SIMD[T,1], mut uy: SIMD[T,1], mut uz: SIMD[T,1]):
        ux = self.R11 * vx + self.R21 * vy + self.R31 * vz
        uy = self.R12 * vx + self.R22 * vy + self.R32 * vz
        uz = self.R13 * vx + self.R23 * vy + self.R33 * vz

    @always_inline
    fn multiplyInverse(self, vx: SIMD[T,1], vy: SIMD[T,1], mut ux: SIMD[T,1], mut uy: SIMD[T,1], mut uz: SIMD[T,1]):
        ux = self.R11 * vx + self.R21 * vy
        uy = self.R12 * vx + self.R22 * vy
        uz = self.R13 * vx + self.R23 * vy

    @always_inline
    fn xx(self) -> ref [self.R11] Scalar[T]:
        return self.R11

    @always_inline
    fn xy(self) -> ref [self.R12] Scalar[T]:
        return self.R12

    @always_inline
    fn xz(self) -> ref [self.R13] Scalar[T]:
        return self.R13
    @always_inline
    fn yx(self) -> ref [self.R21] Scalar[T]:
        return self.R21
    @always_inline
    fn yy(self) -> ref [self.R22] Scalar[T]:
        return self.R22
    @always_inline
    fn yz(self) -> ref [self.R23] Scalar[T]:
        return self.R23
    @always_inline
    fn zx(self) -> ref [self.R31] Scalar[T]:
        return self.R31
    @always_inline
    fn zy(self) -> ref [self.R32] Scalar[T]:
        return self.R32
    @always_inline
    fn zz(self) -> ref [self.R33] Scalar[T]:
        return self.R33
    
struct SOAFrame[T: DType](Movable, Copyable):
    var px: Scalar[T]
    var py: Scalar[T]
    var pz: Scalar[T]
    var rot: SOARotation[T]

    fn __init__(out self):
        self.px = 0
        self.py = 0
        self.pz = 0
        self.rot = SOARotation[T]()

    fn __init__(out self, ix: Scalar[T], iy: Scalar[T], iz: Scalar[T], irot: SOARotation[ T]):
        self.px = ix
        self.py = iy
        self.pz = iz
        self.rot = irot

    fn __copyinit__(out self, other: Self):
        self.px = other.px
        self.py = other.py
        self.pz = other.pz
        self.rot = other.rot
    fn __moveinit__(out self, owned existing: Self):
        self.px = existing.px
        self.py = existing.py
        self.pz = existing.pz
        self.rot = existing.rot^

    @always_inline
    fn rotation(self) -> ref [self.rot] SOARotation[T]:
        return self.rot

    @always_inline
    fn toLocal(self, vx: Scalar[T], vy: Scalar[T], vz: Scalar[T],
               mut ux: Scalar[T], mut uy: Scalar[T], mut uz: Scalar[T]):
        self.rot.multiply(vx - self.px, vy - self.py, vz - self.pz, ux, uy, uz)

    @always_inline
    fn toGlobal(self, vx: Scalar[T], vy: Scalar[T], vz: Scalar[T],
                mut ux: Scalar[T], mut uy: Scalar[T], mut uz: Scalar[T]):
        self.rot.multiplyInverse(vx, vy, vz, ux, uy, uz)
        ux += self.px
        uy += self.py
        uz += self.pz

    @always_inline
    fn toGlobal(self, vx: Scalar[T], vy: Scalar[T],
                mut ux: Scalar[T], mut uy: Scalar[T], mut uz: Scalar[T]):
        self.rot.multiplyInverse(vx, vy, ux, uy, uz)
        ux += self.px
        uy += self.py
        uz += self.pz

    @always_inline
    fn toGlobal(self, cxx: Scalar[T], cxy: Scalar[T], cyy: Scalar[T],
                gl: UnsafePointer[Scalar[T]]):
        r = self.rot

        gl[0] = r.xx() * (r.xx() * cxx + r.yx() * cxy) + r.yx() * (r.xx() * cxy + r.yx() * cyy)
        gl[1] = r.xx() * (r.xy() * cxx + r.yy() * cxy) + r.yx() * (r.xy() * cxy + r.yy() * cyy)
        gl[2] = r.xy() * (r.xy() * cxx + r.yy() * cxy) + r.yy() * (r.xy() * cxy + r.yy() * cyy)
        gl[3] = r.xx() * (r.xz() * cxx + r.yz() * cxy) + r.yx() * (r.xz() * cxy + r.yz() * cyy)
        gl[4] = r.xy() * (r.xz() * cxx + r.yz() * cxy) + r.yy() * (r.xz() * cxy + r.yz() * cyy)
        gl[5] = r.xz() * (r.xz() * cxx + r.yz() * cxy) + r.yz() * (r.xz() * cxy + r.yz() * cyy)

    @always_inline
    fn toLocal(self, ge: UnsafePointer[Scalar[T]],
               mut lxx: Scalar[T], mut lxy: Scalar[T], mut lyy: Scalar[T]):
        r = self.rot
        cxx = ge[0]
        cyx = ge[1]
        cyy = ge[2]
        czx = ge[3]
        czy = ge[4]
        czz = ge[5]

        lxx = r.xx() * (r.xx() * cxx + r.xy() * cyx + r.xz() * czx) +
              r.xy() * (r.xx() * cyx + r.xy() * cyy + r.xz() * czy) +
              r.xz() * (r.xx() * czx + r.xy() * czy + r.xz() * czz)
        
        lxy = r.yx() * (r.xx() * cxx + r.xy() * cyx + r.xz() * czx) +
              r.yy() * (r.xx() * cyx + r.xy() * cyy + r.xz() * czy) +
              r.yz() * (r.xx() * czx + r.xy() * czy + r.xz() * czz)

        lyy = r.yx() * (r.yx() * cxx + r.yy() * cyx + r.yz() * czx) +
              r.yy() * (r.yx() * cyx + r.yy() * cyy + r.yz() * czy) +
              r.yz() * (r.yx() * czx + r.yy() * czy + r.yz() * czz)

    @always_inline
    fn x(self) -> Scalar[T]:
        return self.px

    @always_inline
    fn y(self) -> Scalar[T]:
        return self.py

    @always_inline
    fn z(self) -> Scalar[T]:
        return self.pz