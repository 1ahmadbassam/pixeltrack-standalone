from MojoSerial.MojoBridge.DTypes import Float, Double
from MojoSerial.MojoBridge.Vector import Vector
from MojoSerial.MojoBridge.Matrix import Matrix

from MojoSerial.CUDACore.EigenSoA import MatrixSoA

@fieldwise_init
struct TrajectoryStateSoA[S: Int32](Movable, Copyable):
    alias Vector5f = Vector[DType.float32, 5]
    alias Vector15f = Vector[DType.float32, 15]

    alias Vector5d = Vector[DType.float64, 5]
    alias Matrix5d = Matrix[DType.float64, 5, 5]

    var state: MatrixSoA[Self.Vector5f, Int(S)]
    var covariance: MatrixSoA[Self.Vector15f, Int(S)]

    fn __init__(out self):
        self.state = MatrixSoA[Self.Vector5f, Int(S)](Self.Vector5f())
        self.covariance = MatrixSoA[Self.Vector15f, Int(S)](Self.Vector15f())

    @staticmethod
    @always_inline
    fn stride() -> Int32:
        return S

    @always_inline
    fn copyFromCircle(mut self, cp: Vector[_, 3], ccov: Matrix[_, 3, 3], lp: Vector[_, 2], lcov: Matrix[_, 2, 2], b: Float, i: Int32):
        self.state[i] = cp.cast[DType.float32]().join(lp.cast[DType.float32]())
        self.state[i][2] *= b
        var cov = self.covariance[i]
        cov[0] = ccov[0, 0].cast[DType.float32]()
        cov[1] = ccov[0, 1].cast[DType.float32]()
        cov[2] = b * ccov[0, 2].cast[DType.float32]()
        cov[4] = 0; cov[3] = 0
        cov[5] = ccov[1, 1].cast[DType.float32]()
        cov[6] = b * ccov[1, 2].cast[DType.float32]()
        cov[8] = 0; cov[7] = 0
        cov[9] = b * b * ccov[2, 2].cast[DType.float32]()
        cov[11] = 0; cov[10] = 0
        cov[12] = lcov[0, 0].cast[DType.float32]()
        cov[13] = lcov[0, 1].cast[DType.float32]()
        cov[14] = lcov[1, 1].cast[DType.float32]()

    @always_inline
    fn copyFromDense(mut self, v: Vector[_, 5], cov: Matrix[_, 5, 5], i: Int32):
        self.state[i] = v.cast[DType.float32]()
        var ind: Int = 0
        @parameter
        for j in range(5):
            @parameter
            for k in range(j, 5):
                self.covariance[i][ind] = cov[j, k].cast[DType.float32](); ind += 1

    @always_inline
    fn copyToDense[T1: DType, T2: DType, //](self, mut v: Vector[T1, 5], mut cov: Matrix[T2, 5, 5], i: Int32):
        v = self.state[i].cast[T1]()
        var ind: Int = 0
        @parameter
        for j in range(5):
            cov[j, j] = self.covariance[i][ind].cast[T2](); ind += 1
            @parameter
            for k in range(j + 1, 5):
                cov[j, k] = self.covariance[i][ind].cast[T2](); cov[k, j] = cov[j, k]; ind += 1