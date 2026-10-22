from typing import Union

from nortl import Engine, Segment, to_renderable
from nortl.components import Timer
from nortl.core.protocols import Renderable


class DataSender:
    def __init__(self, engine: Engine):
        self.engine = engine
        self.output = engine.define_output('BIT_OUTPUT', width=1)
        self.timer = Timer(engine, 10)

    @Segment.with_input_slots(data=8)
    def send_data(self, engine: Engine, data: Union[Renderable, int]) -> None:  # noqa: UP007
        data = to_renderable(data)

        engine.set(self.output, 0)  # start bit
        engine.sync()

        for i in range(7):
            engine.set(self.output, data[i])
            engine.sync()

        engine.set(self.output, 1)  # key valid bit
        engine.set(self.output, 1)  # stop bit
        engine.sync()
