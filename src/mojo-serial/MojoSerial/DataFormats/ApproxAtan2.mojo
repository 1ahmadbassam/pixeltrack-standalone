from memory import bitcast
from math import pi

from MojoSerial.MojoBridge.DTypes import Short, Float, Double, HexToFloat

struct ApproxAtan2:
    """
        Approximate atan2 evaluations. Polynomials were obtained using Sollya scripts.
    """

    @staticmethod
    fn approx_atan2f_P[DEGREE: Int](x: Float) -> Float:
        constrained[DEGREE == 3 
                 or DEGREE == 5
                 or DEGREE == 7
                 or DEGREE == 9
                 or DEGREE == 11
                 or DEGREE == 13
                 or DEGREE == 15,
                 "degree of the polynomial to approximate atan(x) must be one of {3, 5, 7, 9, 11, 13, 15}."]()
        var z = x * x

        @parameter
        if DEGREE == 3:
            # degree =  3   => absolute accuracy is  7 bits
            return x * (HexToFloat[0xbf78eed2]() + z * HexToFloat[0x3e448e00]())
        elif DEGREE == 5:
            # degree =  5   => absolute accuracy is  10 bits
            return x * (HexToFloat[0xbf7ecfc8]() + z * (HexToFloat[0x3e93cf3a]() + z * HexToFloat[0xbda27c92]()))
        elif DEGREE == 7:
            # degree =  7   => absolute accuracy is  13 bits
            return x * (HexToFloat[0xbf7fcc7a]() + z * (HexToFloat[0x3ea4710c]() + z * (HexToFloat[0xbe15c65a]() + z * HexToFloat[0x3d1fb050]())))
        elif DEGREE == 9:
            # degree =  9   => absolute accuracy is  16 bits
            return x * (HexToFloat[0xbf7ff73e]() +
                        z * (HexToFloat[0x3ea91dc2]() +
                            z * (HexToFloat[0xbe387bfa]() + z * (HexToFloat[0x3dae672a]() + z * HexToFloat[0xbcaac48a]()))))
        elif DEGREE == 11:
            # degree =  11   => absolute accuracy is  19 bits
            return x * (HexToFloat[0xbf7ffe82]() +
                        z * (HexToFloat[0x3eaa4d90]() +
                            z * (HexToFloat[0xbe462faa]() +
                                    z * (HexToFloat[0x3dee71de]() + z * (HexToFloat[0xbd57a64a]() + z * HexToFloat[0x3c4003a8]())))))
        elif DEGREE == 13:
            # degree =  13   => absolute accuracy is  21 bits
            return x * (HexToFloat[0xbf7fffbe]() +
                        z * (HexToFloat[0x3eaa95a0]() +
                            z * (HexToFloat[0xbe4ad37e]() +
                                    z * (HexToFloat[0x3e077de4]() +
                                        z * (HexToFloat[0xbda30408]() + z * (HexToFloat[0x3d099028]() + z * HexToFloat[0xbbdf05e2]()))))))
        elif DEGREE == 15:
            # degree =  15   => absolute accuracy is  24 bits
            return x * (HexToFloat[0xbf7ffff4]() +
                        z * (HexToFloat[0x3eaaa5f2]() + 
                            z * (HexToFloat[0xbe4c3dca]() +
                                    z * (HexToFloat[0x3e0e6098]() +
                                        z * (HexToFloat[0xbdc54406]() +
                                            z * (HexToFloat[0x3d6484d6]() + z * (HexToFloat[0xbcb27aa0]() + z * HexToFloat[0x3b843aee]())))))))
        else:
            # will never happen
            return 0

    @staticmethod
    fn unsafe_atan2f_impl[DEGREE: Int](y: Float, x: Float) -> Float:
        alias pi4f: Float = 3.1415926535897932384626434 / 4
        alias pi34f: Float = 3.1415926535897932384626434 * 3 / 4

        var r: Float = (abs(x) - abs(y)) / (abs(x) + abs(y))
        if x < 0:
            r = -r

        var angle: Float = pi4f if x >= 0 else pi34f
        angle += Self.approx_atan2f_P[DEGREE](r)

        return -angle if y < 0 else angle

    @staticmethod
    fn unsafe_atan2f[DEGREE: Int](y: Float, x: Float) -> Float:
        return Self.unsafe_atan2f_impl[DEGREE](y, x)
    
    @staticmethod
    fn safe_atan2f[DEGREE: Int](y: Float, x: Float) -> Float:
        return Self.unsafe_atan2f[DEGREE](y, 0.2 if y == 0 and x == 0 else x)

    @staticmethod
    fn approx_atan2i_P[DEGREE: Int](x: Float) -> Float:
        constrained[DEGREE == 3 
                 or DEGREE == 5
                 or DEGREE == 7
                 or DEGREE == 9
                 or DEGREE == 11
                 or DEGREE == 13
                 or DEGREE == 15,
                 "degree of the polynomial to approximate atan(x) must be one of {3, 5, 7, 9, 11, 13, 15}."]()
        var z = x * x

        @parameter
        if DEGREE == 3:
            # degree =  3   => absolute accuracy is  6*10^6
            return x * (-664694912 + z * 131209024)
        elif DEGREE == 5:
            # degree =  5   => absolute accuracy is  4*10^5
            return x * (-680392064 + z * (197338400 + z * (-54233256)))
        elif DEGREE == 7:
            # degree =  7   => absolute accuracy is  6*10^4
            return x * (-683027840 + z * (219543904 + z * (-99981040 + z * 26649684)))
        elif DEGREE == 9:
            # degree =  9   => absolute accuracy is  8000
            return x * (-683473920 + z * (225785056 + z * (-123151184 + z * (58210592 + z * (-14249276)))))
        elif DEGREE == 11:
            # degree =  11   => absolute accuracy is  1000
            return x *
                    (-683549696 + z * (227369312 + z * (-132297008 + z * (79584144 + z * (-35987016 + z * 8010488)))))
        elif DEGREE == 13:
            # degree =  13   => absolute accuracy is  163
            return x * (-683562624 +
                        z * (227746080 +
                            z * (-135400128 + z * (90460848 + z * (-54431464 + z * (22973256 + z * (-4657049)))))))
        elif DEGREE == 15:
            return x * (-683562624 +
                        z * (227746080 +
                            z * (-135400128 + z * (90460848 + z * (-54431464 + z * (22973256 + z * (-4657049)))))))
        else:
            # will never happen
            return 0

    @staticmethod
    fn unsafe_atan2i_impl[DEGREE: Int](y: Float, x: Float) -> Int:
        alias pi4: Int = Int((Int32.MAX.cast[DType.int64]() + 1) // 4)
        alias pi34: Int = Int(3 * (Int32.MAX.cast[DType.int64]() + 1) // 4)

        var r: Float = (abs(x) - abs(y)) / (abs(x) + abs(y))
        if x < 0:
            r = -r

        var angle: Int = pi4 if x >= 0 else pi34
        angle += Int(Self.approx_atan2i_P[DEGREE](r))

        return -angle if y < 0 else angle

    @staticmethod
    fn unsafe_atan2i[DEGREE: Int](y: Float, x: Float) -> Int:
        return Self.unsafe_atan2i_impl[DEGREE](y, x)

    @staticmethod
    fn approx_atan2s_P[DEGREE: Int](x: Float) -> Float:
        constrained[DEGREE == 3 
                 or DEGREE == 5
                 or DEGREE == 7
                 or DEGREE == 9,
                 "degree of the polynomial to approximate atan(x) must be one of {3, 5, 7, 9}."]()
        var z = x * x

        @parameter
        if DEGREE == 3:
            # degree =  3   => absolute accuracy is  53
            return x * ((-10142.439453125) + z * 2002.0908203125)
        elif DEGREE == 5:
            # degree =  5   => absolute accuracy is  7
            return x * ((-10381.9609375) + z * ((3011.1513671875) + z * (-827.538330078125)))
        elif DEGREE == 7:
            # degree =  7   => absolute accuracy is  2
            return x * ((-10422.177734375) + z * (3349.97412109375 + z * ((-1525.589599609375) + z * 406.64190673828125)))
        elif DEGREE == 9:
            # degree =  9   => absolute accuracy is 1
            return x * ((-10428.984375) + z * (3445.20654296875 + z * ((-1879.137939453125) +
                                                                        z * (888.22314453125 + z * (-217.42669677734375)))))
        else:
            # will never happen
            return 0
    
    @staticmethod
    fn unsafe_atan2s_impl[DEGREE: Int](y: Float, x: Float) -> Short:
        alias pi4: Short = ((Int16.MAX.cast[DType.int64]() + 1) // 4).cast[DType.int16]()
        alias pi34: Short = (3 * (Int16.MAX.cast[DType.int64]() + 1) // 4).cast[DType.int16]()

        var r: Float = (abs(x) - abs(y)) / (abs(x) + abs(y))
        if x < 0:
            r = -r

        var angle: Short = pi4 if x >= 0 else pi34
        angle += Self.approx_atan2i_P[DEGREE](r).cast[DType.int16]()

        return -angle if y < 0 else angle

    @staticmethod
    fn unsafe_atan2s[DEGREE: Int](y: Float, x: Float) -> Short:
        return Self.unsafe_atan2s_impl[DEGREE](y, x)

    @staticmethod
    fn phi2int(x: Float) -> Int:
        alias p2i: Float = ((Int32.MAX.cast[DType.int64]() + 1).cast[DType.float32]()/ pi)
        return Int(round(x * p2i))

    @staticmethod
    fn int2phi(x: Int) -> Float:
        alias i2p: Float = (pi / (Int32.MAX.cast[DType.int64]() + 1).cast[DType.float32]())
        return Float(x) * i2p
    
    @staticmethod
    fn int2dphi(x: Int) -> Double:
        alias i2p: Double = (pi / (Int32.MAX.cast[DType.int64]() + 1).cast[DType.float64]())
        return Double(x) * i2p
    
    @staticmethod
    fn phi2short(x: Float) -> Short:
        alias p2i: Float = ((Int16.MAX.cast[DType.int32]() + 1).cast[DType.float32]()/ pi)
        return Short(round(x * p2i))
    
    @staticmethod
    fn short2phi(x: Short) -> Float:
        alias i2p: Float = (pi / (Int16.MAX.cast[DType.int32]() + 1).cast[DType.float32]())
        return Float(x) * i2p
