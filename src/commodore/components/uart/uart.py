from nortl import Const, Engine

from commodore.components.text_writer import TextWriter
from commodore.components.uart.data_reader import DataReader


class UART:
    def __init__(self, engine: Engine, text_writer: TextWriter, bit_ticks: int = 64):
        self.engine = engine
        self.text_writer = text_writer
        self.data_reader = DataReader(engine, bit_ticks)

    def run(self) -> None:
        with self.engine.while_loop(Const(True)):
            byte = self.data_reader.read_data()
            self.text_writer.user_write(self.engine, byte)
