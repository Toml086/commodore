from nortl import Engine, Segment
from nortl.components import Timer
from nortl.core import Signal


class DataReader:
    def __init__(self, engine: Engine):
        self.engine = engine
        self.input = engine.define_input('BIT_INPUT', 1)
        self.timer = Timer(engine, 10)

    @Segment.with_input_slots(data=8)
    def read_data(self, engine: Engine, data: Signal) -> None:
        shift = engine.define_local('INPUT_SHIFT', 8, 0)
        for _ in range(8):
            engine.set(shift, (shift >> 1) | (self.input << 7))
            engine.sync()
        engine.set(data, shift)
