from typing import Union

from nortl import Engine, to_renderable
from nortl.core.protocols import OperationTraitProto, Renderable

from input_device.uart.uart_timing import wait_ticks


class DataSender:
    def __init__(self, engine: Engine, bit_ticks: int = 64):
        self.engine = engine
        self.bit_ticks = bit_ticks
        self.output = engine.define_output('BIT_OUTPUT', width=1, reset_value=1)
        self.counter = engine.define_local('TX_COUNTER', 16, 0)

    def idle(self) -> None:
        self.engine.set(self.output, 1)
        self.engine.sync()

    def bit(self, value: OperationTraitProto | int) -> None:
        self.engine.set(self.output, value)
        wait_ticks(self.engine, self.counter, self.bit_ticks)

    def send_data(self, engine: Engine, data: Union[Renderable, int]) -> None:  # noqa: UP007
        data = to_renderable(data)

        self.bit(0)  # startbit

        for i in range(8):
            self.bit(data[i])
        self.bit(1)  # stopbit
