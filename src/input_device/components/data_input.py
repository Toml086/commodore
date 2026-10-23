from nortl import Engine
from nortl.core import Signal

from input_device.uart.data_sender import DataSender


class DataInput:
    def __init__(self, engine: Engine, data_sender: DataSender):
        self.engine = engine
        self.data_sender = DataSender(engine)

    def call_uart_sender(self, signal_input: Signal) -> None:
        self.data_sender.idle()
        self.data_sender.send_data(self.engine, signal_input)
