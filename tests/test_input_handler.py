from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.tables.input_handler import InputHandler

# test for input handler and units of text_writer


class TestInputHandler(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')

        self.in_handler = InputHandler(engine)
        self.data_source = engine.define_local('LOCAL', 6, 0)

        return engine

    def dut(self, engine: Engine) -> None:
        pass

    def the_testbench(self, engine: Engine) -> None:
        # ------Case1 - converts valid input to valid signal------
        # Arrange & Act
        user_input = 'A'
        handled_user_input = self.in_handler.handle_input(user_input)
        value_local = self.engine.define_local('VALUE_INDEX', 6)
        self.engine.set(value_local, handled_user_input)

        assertion_local = self.engine.define_local('ASSERTION_INDEX', 6)
        self.engine.set(assertion_local, 33)

        # Assert
        self.assertEqual(assertion_local, value_local)

        # ------Case2 - converts unknown input to space(index 0)------
        # Arrange & Act
        user_input = 'Ä'
        handled_user_input = self.in_handler.handle_input(user_input)
        value_local = self.engine.define_local('VALUE_INDEX_INVALID', 6)
        self.engine.set(value_local, handled_user_input)

        assertion_local = self.engine.define_local('ASSERTION_INDEX_ZERO', 6)
        self.engine.set(assertion_local, 0)

        # Assert
        self.assertEqual(assertion_local, value_local)
