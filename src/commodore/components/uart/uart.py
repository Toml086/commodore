from nortl import Const, Engine

from commodore.components.text_writer import TextWriter
from commodore.components.uart.data_reader import DataReader
from input_device.engine_input import InputEngine


class UART:
    def __init__(self, engine: Engine, text_writer: TextWriter, input_engine: InputEngine, bit_ticks: int = 64):
        self.engine = engine
        self.text_writer = text_writer
        self.data_reader = DataReader(engine, bit_ticks)
        self.input_engine = InputEngine('INPUT_DEVICE')

    def run(self) -> None:
        with self.engine.while_loop(Const(True)):
            byte = self.data_reader.read_data(self.input_engine.data_sender.output)
            self.text_writer.user_write(self.engine, byte)
