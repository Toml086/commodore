from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.look_up_table import LookUpTable


class TestNormalConvert(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')

        self.lut = LookUpTable(engine)
        self.data_source = engine.define_local(6, 0)

        return engine

    def dut(self, engine: Engine) -> None:
        pass

    def the_testbench(self, engine: Engine) -> None:
        # converts valid input to valid signal
        user_input = 'A'
        self.lut.read
