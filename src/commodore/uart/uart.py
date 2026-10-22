from nortl import Engine

from commodore.uart.data_reader import DataReader
from commodore.uart.data_sender import DataSender


class UART:
    def __init__(self, engine: Engine):
        self.engine = engine
        self.data_sender = DataSender(engine)
        self.data_reader = DataReader(engine)

    def uart_protocol(self):
        self.engine.wait_for(self.data_reader.input.falling())
