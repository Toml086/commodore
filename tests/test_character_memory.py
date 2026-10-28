from coverage_test_base import CoverageTestBase
from nortl import Engine

from commodore.engine import MainEngine

# test for char memory and units of text_writer


class CharMemoryTestBase(CoverageTestBase):
    def init_sequence(self) -> Engine:
        self.main_engine = MainEngine('my_engine')

        self.data_source = self.main_engine.define_local('data_source', 6, 0)

        return self.main_engine

    def dut(self, engine: Engine) -> None:
        pass


class TestInitialState(CharMemoryTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        cell_0_0 = self.main_engine.char_memory.read(0, 0)

        # Assert
        self.assertEqual(cell_0_0, 0)


class TestReadAndWrite(CharMemoryTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act

        self.main_engine.char_memory.write(1, 1, self.data_source)
        read_signal = self.main_engine.char_memory.read(1, 1)
        # Assert
        self.assertEqual(self.data_source, read_signal)


class TestIndexOutOfBoundError(CharMemoryTestBase):
    def the_testbench(self, engine: Engine) -> None:
        try:
            self.main_engine.char_memory.write(0, 40, self.data_source)
            self.assertTrue(False)
        except IndexError:
            self.assertTrue(True)


class TestFillAndReadAllFields(CharMemoryTestBase):
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

                self.assertEqual(read_signal, expected_value)
