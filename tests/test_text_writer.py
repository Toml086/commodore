from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.character_memory import CharacterMemory
from commodore.cursor import Cursor
from commodore.input_handler import InputHandler
from commodore.text_writer import TextWriter

# test for text writer and cursor


class TestTextWriter(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')
        self.cursor = Cursor(engine)
        self.char_memory = CharacterMemory(engine)
        self.input_handler = InputHandler(engine)

        self.text_writer = TextWriter(engine, 'test', self.cursor, self.char_memory, self.input_handler)

        return engine

    def dut(self, engine: Engine) -> None:
        pass

    def the_testbench(self, engine: Engine) -> None:
        # ------Case1 - normal write------
        # Arrange & Act
        self.text_writer.user_write(engine, 'A')

        test_signal_local = engine.define_local('TEST_LOCAL', 6)
        engine.set(test_signal_local, 33)
        char_0_0 = self.char_memory.read(0, 0)

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        self.assertEqual(test_signal_local, char_0_0)
        assert (cursor_pos_row, cursor_pos_col) == (0, 1)

        # ------Case2 - write multiple chars------
        # Arrange & Act
        self.cursor.set_position(0, 0)
        self.text_writer.user_write(engine, 'A')
        self.text_writer.user_write(engine, 'B')
        self.text_writer.user_write(engine, 'C')
        self.text_writer.user_write(engine, 'D')

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()
        char_0_0 = self.char_memory.read(0, 0)
        char_0_1 = self.char_memory.read(0, 1)
        char_0_2 = self.char_memory.read(0, 2)
        char_0_3 = self.char_memory.read(0, 3)

        test_signal_local_0_0 = engine.define_local('TEST_LOCAL_0_0', 6)
        engine.set(test_signal_local_0_0, 33)

        test_signal_local_0_1 = engine.define_local('TEST_LOCAL_0_1', 6)
        engine.set(test_signal_local_0_1, 34)

        test_signal_local_0_2 = engine.define_local('TEST_LOCAL_0_2', 6)
        engine.set(test_signal_local_0_2, 35)

        test_signal_local_0_3 = engine.define_local('TEST_LOCAL_0_3', 6)
        engine.set(test_signal_local_0_3, 36)

        # Assert
        self.assertEqual(test_signal_local_0_0, char_0_0)
        self.assertEqual(test_signal_local_0_1, char_0_1)
        self.assertEqual(test_signal_local_0_2, char_0_2)
        self.assertEqual(test_signal_local_0_3, char_0_3)
        assert (cursor_pos_row, cursor_pos_col) == (0, 4)

        # ------Case3 - line break for end of row------
        # Arrange & Act
        self.cursor.set_position(0, 38)
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, 'E')

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        assert (cursor_pos_row, cursor_pos_col) == (1, 0)

        # ------Case4 - line break for end of table------
        # Arrange & Act
        self.cursor.set_position(24, 38)
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, 'E')

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        assert (cursor_pos_row, cursor_pos_col) == (0, 0)

        # ------Case5 - normal clear------
        # Arrange & Act
        self.cursor.set_position(0, 0)
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, '!')  # command for clear()

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()
        test_signal_local_empty = engine.define_local('TEST_LOCAL_EMPTY', 6)
        engine.set(test_signal_local_empty, 0)

        # Assert
        self.assertEqual(test_signal_local_empty, self.char_memory.read(0, 0))
        assert (cursor_pos_row, cursor_pos_col) == (0, 0)

        # ------Case6 - clear multiple chars------
        # Arrange & Act
        self.cursor.set_position(0, 0)
        self.text_writer.user_write(engine, 'H')
        self.text_writer.user_write(engine, 'E')
        self.text_writer.user_write(engine, 'L')
        self.text_writer.user_write(engine, 'L')
        self.text_writer.user_write(engine, 'O')

        self.text_writer.user_write(engine, '!')  # command for clear()
        self.text_writer.user_write(engine, '!')  # command for clear()

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        C6_test_signal_local_0_0 = engine.define_local('C6_TEST_LOCAL_0_0', 6)
        engine.set(C6_test_signal_local_0_0, 40)

        C6_test_signal_local_0_1 = engine.define_local('C6_TEST_LOCAL_0_1', 6)
        engine.set(C6_test_signal_local_0_1, 37)

        C6_test_signal_local_0_2 = engine.define_local('C6_TEST_LOCAL_0_2', 6)
        engine.set(C6_test_signal_local_0_2, 44)

        C6_test_signal_local_0_3 = engine.define_local('C6_TEST_LOCAL_0_3', 6)
        engine.set(C6_test_signal_local_0_3, 0)

        C6_test_signal_local_0_4 = engine.define_local('C6_TEST_LOCAL_0_4', 6)
        engine.set(C6_test_signal_local_0_4, 0)

        # Assert
        self.assertEqual(C6_test_signal_local_0_0, self.char_memory.read(0, 0))
        self.assertEqual(C6_test_signal_local_0_1, self.char_memory.read(0, 1))
        self.assertEqual(C6_test_signal_local_0_2, self.char_memory.read(0, 2))
        self.assertEqual(C6_test_signal_local_0_3, self.char_memory.read(0, 3))
        self.assertEqual(C6_test_signal_local_0_4, self.char_memory.read(0, 4))
        assert (cursor_pos_row, cursor_pos_col) == (0, 3)

        # ------Case7 - line break for start of row------
        # Arrange & Act
        self.cursor.set_position(1, 1)
        self.text_writer.user_write(engine, '!')
        self.text_writer.user_write(engine, '!')

        C7_zero_signal_local = engine.define_local('C7_zero_signal_local', 6)
        engine.set(C7_zero_signal_local, 0)

        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        self.assertEqual(C7_zero_signal_local, self.char_memory.read(1, 0))
        self.assertEqual(C7_zero_signal_local, self.char_memory.read(0, 39))
        assert (cursor_pos_row, cursor_pos_col) == (0, 39)

        # ------Case8 - line break for start of table (does nothing)------
        # Arrange & Act
        self.cursor.set_position(0, 0)

        self.text_writer.user_write(engine, '!')
        cursor_pos_row, cursor_pos_col = self.cursor.get_position()

        # Assert
        assert (cursor_pos_row, cursor_pos_col) == (0, 0)

        # ------Case9 - normal use of clear all------
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
