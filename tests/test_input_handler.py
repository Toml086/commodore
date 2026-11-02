from commodore_test_base import CommodoreTestBase
from nortl import Engine

# test for input handler and units of text_writer


class TestConvertsValidInputToValidSignal(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.start_uart()
        self.send_bytes(0x41)  # =A

        # Assert
        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 33)

        self.finish_simulation()


class TestConvertsValidUnknownInputToSpace(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.start_uart()
        self.send_bytes(0xC4)  # =Ä

        # Assert
        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 31)

        self.finish_simulation()
