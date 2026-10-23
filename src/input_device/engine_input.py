from nortl import Const, Engine

from input_device.components.data_input import DataInput
from input_device.uart.data_sender import DataSender


class InputEngine(Engine):
    def __init__(self, name: str):
        super().__init__(name)
        self.data_sender = DataSender(self)
        self.data_input = DataInput(self, self.data_sender)

        self.key_code = self.define_input('KEY_CODE', 8)
        self.key_valid = self.define_input('KEY_VALID', 1)

        self.input_local = self.define_local('LOCAL_INPUT', 8, 0)

    def build(self) -> None:
        self.sync()
        self.data_sender.idle()

        with self.while_loop(Const(True)):
            self.wait_for(self.key_valid.rising())
            self.set(self.input_local, self.key_code)
            self.sync()
            self.data_sender.send_data(self, self.input_local)

        with open('Input.svw') as fptr:
            fptr.write(self.to_verilog())


if __name__ == '__main__':
    engine = InputEngine('input')
    engine.build()
