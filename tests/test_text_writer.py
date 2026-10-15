from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.components.text_writer import TextWriter
from commodore.tables.input_handler import InputHandler

# test for text writer and cursor


class TextWriterTestBase(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')
        self.cursor = Cursor(engine)
        self.char_memory = CharacterMemory(engine)
        self.input_handler = InputHandler(engine)

        self.text_writer = TextWriter(engine, self.cursor, self.char_memory, self.input_handler)

        return engine

    def dut(self, engine: Engine) -> None:
        pass


class TestNormalWrite(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.text_writer.user_write(engine, 'A')

        test_signal_local = engine.define_local('TEST_LOCAL', 6)
        engine.set(test_signal_local, 33)

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        self.assertEqual(test_signal_local, self.char_memory.read(0, 0))
        assert (cursor_pos_row, cursor_pos_col) == (0, 1)


class TestWriteMultipleChars(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.text_writer.user_write(engine, 'A')
        self.text_writer.user_write(engine, 'B')
        self.text_writer.user_write(engine, 'C')
        self.text_writer.user_write(engine, 'D')

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        test_signal_local_0_0 = engine.define_local('TEST_LOCAL_0_0', 6)
        engine.set(test_signal_local_0_0, 33)

        test_signal_local_0_1 = engine.define_local('TEST_LOCAL_0_1', 6)
        engine.set(test_signal_local_0_1, 34)

        test_signal_local_0_2 = engine.define_local('TEST_LOCAL_0_2', 6)
        engine.set(test_signal_local_0_2, 35)

        test_signal_local_0_3 = engine.define_local('TEST_LOCAL_0_3', 6)
        engine.set(test_signal_local_0_3, 36)

        # Assert
        self.assertEqual(test_signal_local_0_0, self.char_memory.read(0, 0))
        self.assertEqual(test_signal_local_0_1, self.char_memory.read(0, 1))
        self.assertEqual(test_signal_local_0_2, self.char_memory.read(0, 2))
        self.assertEqual(test_signal_local_0_3, self.char_memory.read(0, 3))
        assert (cursor_pos_row, cursor_pos_col) == (0, 4)


class TestLineBreakForEndOfRow(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.cursor.set_position(0, 38)
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, 'E')

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        assert (cursor_pos_row, cursor_pos_col) == (1, 0)


class TestLineBreakForEndOfTable(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.cursor.set_position(24, 38)
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, 'E')

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        assert (cursor_pos_row, cursor_pos_col) == (0, 0)


class TestNormalClear(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, '!')  # command for clear()

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()
        test_signal_local_empty = engine.define_local('TEST_LOCAL_EMPTY', 6)
        engine.set(test_signal_local_empty, 0)

        # Assert
        self.assertEqual(test_signal_local_empty, self.char_memory.read(0, 0))
        assert (cursor_pos_row, cursor_pos_col) == (0, 0)


class TestClearMultipleChars(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, 'E')
        self.text_writer.user_write(engine, 'L')
        self.text_writer.user_write(engine, 'L')
        self.text_writer.user_write(engine, 'O')

        self.text_writer.user_write(engine, '!')  # command for clear()
        self.text_writer.user_write(engine, '!')  # command for clear()

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        test_signal_local_0_0 = engine.define_local('TEST_LOCAL_0_0', 6)
        engine.set(test_signal_local_0_0, 40)

        test_signal_local_0_1 = engine.define_local('TEST_LOCAL_0_1', 6)
        engine.set(test_signal_local_0_1, 37)

        test_signal_local_0_2 = engine.define_local('TEST_LOCAL_0_2', 6)
        engine.set(test_signal_local_0_2, 44)

        test_signal_local_0_3 = engine.define_local('TEST_LOCAL_0_3', 6)
        engine.set(test_signal_local_0_3, 0)

        test_signal_local_0_4 = engine.define_local('TEST_LOCAL_0_4', 6)
        engine.set(test_signal_local_0_4, 0)

        # Assert
        self.assertEqual(test_signal_local_0_0, self.char_memory.read(0, 0))
        self.assertEqual(test_signal_local_0_1, self.char_memory.read(0, 1))
        self.assertEqual(test_signal_local_0_2, self.char_memory.read(0, 2))
        self.assertEqual(test_signal_local_0_3, self.char_memory.read(0, 3))
        self.assertEqual(test_signal_local_0_4, self.char_memory.read(0, 4))
        assert (cursor_pos_row, cursor_pos_col) == (0, 3)


class TestLineBreakForStartOfRow(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.cursor.set_position(1, 1)
        self.text_writer.user_write(engine, '!')
        self.text_writer.user_write(engine, '!')

        zero_signal_local = engine.define_local('zero_signal_local', 6)
        engine.set(zero_signal_local, 0)

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        self.assertEqual(zero_signal_local, self.char_memory.read(1, 0))
        self.assertEqual(zero_signal_local, self.char_memory.read(0, 39))
        assert (cursor_pos_row, cursor_pos_col) == (0, 39)


class TestLineBreakStartOfTable(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # (expected: does nothing)
        # Arrange & Act

        self.text_writer.user_write(engine, '!')
        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        assert (cursor_pos_row, cursor_pos_col) == (0, 0)


class TestNormalUseClearAllRandomInputs(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.text_writer.user_write(engine, 'H')
        self.cursor.set_position(0, 5)
        self.text_writer.user_write(engine, 'E')
        self.cursor.set_position(1, 3)
        self.text_writer.user_write(engine, 'L')
        self.cursor.set_position(5, 20)
        self.text_writer.user_write(engine, 'L')
        self.cursor.set_position(20, 20)
        self.text_writer.user_write(engine, 'O')

        test_signal_zero_local = engine.define_local('test_local', 6)
        engine.set(test_signal_zero_local, 0)

        self.text_writer.user_write(engine, '?')  # command for clear_all()
        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        assert (cursor_pos_row, cursor_pos_col) == (0, 0)
        self.assertEqual(test_signal_zero_local, self.char_memory.read(0, 0))
        self.assertEqual(test_signal_zero_local, self.char_memory.read(0, 5))
        self.assertEqual(test_signal_zero_local, self.char_memory.read(1, 3))
        self.assertEqual(test_signal_zero_local, self.char_memory.read(5, 20))
        self.assertEqual(test_signal_zero_local, self.char_memory.read(20, 20))


class TestClearAllWithAllFieldsFilled(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        for row in range(25):
            for col in range(40):
                target_value = (row + col) % 63 + 1
                dynamic_signal = engine.define_local(f'dym_signal{row}_{col}', 6)
                engine.set(dynamic_signal, target_value)
                engine.sync()
                self.char_memory.write(row, col, dynamic_signal)

        self.text_writer.user_write(engine, '?')  # command for clear_all()

        # Assert
        for row in range(25):
            for col in range(40):
                read_signal = self.char_memory.read(row, col)

                self.assertEqual(read_signal, 0)
