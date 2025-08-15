from time import perf_counter_ns


@register_passable("trivial")
struct Timer(Copyable, Defaultable, Movable, Stringable):
    var _start: UInt
    var _time: UInt

    @always_inline
    fn __init__(out self):
        self._start = 0
        self._time = 0

    @always_inline
    fn __init__(out self, var start: UInt):
        self._start = start
        self._time = 0

    @always_inline
    fn start(mut self):
        self._start = perf_counter_ns()

    @always_inline
    fn finish(mut self):
        self._time += perf_counter_ns() - self._start

    @always_inline
    fn get(self) -> UInt:
        return self._time

    @always_inline
    fn finalize(self, var name: String):
        print(
            "[" + name + "] completed in ",
            self._time // (10**6),
            "ms",
            sep="",
        )

    @always_inline
    fn __str__(self) -> String:
        return (
            "Timer(" + self._start.__str__() + ", " + self._time.__str__() + ")"
        )


struct TimerManager(Defaultable, Movable, Sized):
    var _storage: Dict[String, Timer]
    # a stack
    var _cur: List[String]

    @always_inline
    fn __init__(out self):
        self._storage = {}
        self._cur = []

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self._storage = other._storage^
        self._cur = other._cur^

    @always_inline
    fn __enter__(mut self):
        if not self.empty():
            if self.top() not in self._storage:
                self._storage[self.top()] = Timer()
            try:
                self._storage[self.top()].start()
            except e:
                print(e)

    @always_inline
    fn __exit__(mut self):
        try:
            self._storage[self.top()].finish()
        except e:
            print(e)
        self.pop()

    @always_inline
    fn configure(mut self, var name: String):
        self._cur.append(name)

    @always_inline
    fn start(mut self, var name: String = ""):
        if name:
            self.configure(name)
        self.__enter__()

    @always_inline
    fn stop(mut self):
        self.__exit__()

    @always_inline
    fn empty(self) -> Bool:
        return self._cur.__len__() == 0

    @always_inline
    fn top(ref self) -> ref [self._cur] String:
        return self._cur[-1]

    @always_inline
    fn pop(mut self):
        _ = self._cur.pop()

    @always_inline
    fn __len__(self) -> Int:
        return self._storage.__len__()

    @always_inline
    fn finalize(mut self):
        try:
            while not self.empty():
                self.stop()
            for k in self._storage.keys():
                self._storage[k].finalize(k)
        except e:
            print(e)
