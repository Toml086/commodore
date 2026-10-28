from coverage_test_base import CoverageTestBase
from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.engine import MainEngine

# test for input handler and units of text_writer


class InputHandlerTestBase(CoverageTestBase):
    def init_sequence(self) -> Engine:
        self.main_engine = MainEngine('my_engine')

        self.data_source = self.main_engine.define_local('LOCAL', 6, 0)

        return self.main_engine

    def dut(self, engine: Engine) -> None:
        pass


class TestConvertsValidInputToValidSignal(InputHandlerTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        user_input = 0x41  # =A
        key_code = engine.define_local('KEY_CODE', 8)
        engine.set(key_code, user_input)
        self.main_engine.input_handler.handle_input(engine, key_code)

        # Assert
        self.assertEqual(self.main_engine.input_handler.result, 33)


class TestConvertsValidUnknownInputToSpace(InputHandlerTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        user_input = 0xC4  # =Ä
        key_code = engine.define_local('KEY_CODE', 8)
        engine.set(key_code, user_input)
        self.main_engine.input_handler.handle_input(engine, key_code)

        # Assert
        self.assertEqual(self.main_engine.input_handler.result, 31)
