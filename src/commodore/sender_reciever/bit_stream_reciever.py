from typing import Union

from nortl import Engine, Segment, to_renderable
from nortl.core.operations import Renderable
from nortl.core.protocols import EngineProto


class BitStreamSender:
    def __init__(self, engine: EngineProto):
        self.engine = engine
        self.output = engine.define_output('OUTPUT', width=1)

    @Segment
    def send_data(self, data: Union[Renderable, int]) -> None:
        data = to_renderable(data)
        for i in range(6):
            self.engine.set(self.output, data[i])
            self.engine.sync()
