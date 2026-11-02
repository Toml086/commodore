from commodore_test_base import CommodoreTestBase
from nortl import Engine

# test for char memory and units of text_writer


class TestInitialState(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 0)

        self.finish_simulation()


class TestReadAndWrite(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act

        self.start_uart()
        self.send_bytes(0x41)  # =A, at 0,0

        self.send_bytes(0x42)  # =B, at 0,1

        # Assert
        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 33)
        self.assertTrue(self.main_engine.char_memory.read(0, 1) == 34)

        self.finish_simulation()


class TestIndexOutOfBoundError(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        try:
            self.main_engine.char_memory.write(0, 40, self.data_source)
            self.assertTrue(False)
        except IndexError:
            self.assertTrue(True)

        self.finish_simulation()


""" class TestFillAndReadAllFields(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        for row in range(self.main_engine.char_memory.height):
            for col in range(self.main_engine.char_memory.width):
                target_value = (row + col) % 64
                dynamic_signal = engine.define_local(f'dyn_sig_{row}_{col}', 6, reset_value=target_value)

                self.main_engine.char_memory.write(row, col, dynamic_signal)

        for row in range(self.main_engine.char_memory.height):
            for col in range(self.main_engine.char_memory.width):
                expected_value = (row + col) % 64

                read_signal = self.main_engine.char_memory.read(row, col)

                self.assertTrue(read_signal == expected_value)

        self.finish_simulation() """
