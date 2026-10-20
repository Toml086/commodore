from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.tables.input_handler import InputHandler

# test for input handler and units of text_writer


class InputHandlerTestBase(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')

        self.input_handler = InputHandler(engine)
        self.data_source = engine.define_local('LOCAL', 6, 0)

        return engine

    def dut(self, engine: Engine) -> None:
        pass


class TestConvertsValidInputToValidSignal(InputHandlerTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        user_input = 0x41  # =A
        key_code = engine.define_local('KEY_CODE', 8)
        engine.set(key_code, user_input)
        self.input_handler.handle_input(engine, key_code)

        # Assert
        self.assertEqual(self.input_handler.result, 33)


class TestConvertsValidUnknownInputToSpace(InputHandlerTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        user_input = 0xC4  # =Ä
        key_code = engine.define_local('KEY_CODE', 8)
        engine.set(key_code, user_input)
        self.input_handler.handle_input(engine, key_code)

        # Assert
        self.assertEqual(self.input_handler.result, 0)
