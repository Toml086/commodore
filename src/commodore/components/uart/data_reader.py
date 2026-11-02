from nortl import Const, Engine, IfThenElse
from nortl.core import Signal

from commodore.components.uart.uart_timing import wait_ticks


class DataReader:
    def __init__(self, engine: Engine, bit_ticks: int = 64, start_offset: int = 3):
        self.engine = engine
        self.bit_ticks = bit_ticks
        self.start_offset = start_offset

        self.counter = engine.define_local('RX_COUNTER', 16, 0)
        self.bit_idx = engine.define_local('RX_BIT_IDX', 4, 0)
        self.shift = engine.define_local('RX_SHIFT', 8, 0)
        self.byte = engine.define_local('RX_BYTE', 8, 0)

    def read_data(self, input_signal: Signal) -> Signal:
        self.engine.wait_for(input_signal.falling())  # startbit
        wait_ticks(self.engine, self.counter, self.bit_ticks + self.bit_ticks // 2 - self.start_offset)

        self.engine.set(self.bit_idx, 0)
        self.engine.sync()
        with self.engine.while_loop(self.bit_idx != 8):
            new_bit = IfThenElse(input_signal, Const(0x80, 8), Const(0, 8))  # 1 -> 10000000;    0 -> 00000000
            self.engine.set(self.shift, (self.shift >> 1) | new_bit)
            self.engine.set(self.bit_idx, self.bit_idx + 1)
            wait_ticks(self.engine, self.counter, self.bit_ticks)

        self.engine.set(self.byte, self.shift)
        self.engine.sync()

        return self.byte
