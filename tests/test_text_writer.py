from coverage_test_base import CoverageTestBase
from nortl import Engine

from commodore.engine import MainEngine

# test for text writer and cursor


class TextWriterTestBase(CoverageTestBase):
    def init_sequence(self) -> Engine:
        self.main_engine = MainEngine('my_engine')

        self.key_code = self.main_engine.define_local('KEY_CODE', 8)

        return self.main_engine

    def dut(self, engine: Engine) -> None:
        pass


class TestNormalWrite(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        engine.set(self.key_code, 0x41)  # =A
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(1, self.main_engine.cursor.col)
        self.assertEqual(0, self.main_engine.cursor.row)

        self.assertEqual(33, self.main_engine.char_memory.read(0, 0))


class TestWriteMultipleChars(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act

        engine.set(self.key_code, 0x42)  # =B
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x31)  # =1
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x4F)  # =O
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(3, self.main_engine.cursor.col)

        self.assertEqual(34, self.main_engine.char_memory.read(0, 0))
        self.assertEqual(17, self.main_engine.char_memory.read(0, 1))
        self.assertEqual(47, self.main_engine.char_memory.read(0, 2))


class TestLineBreakForEndOfRow(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.main_engine.cursor.set_position(38, 0)

        engine.set(self.key_code, 0x48)  # =H
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x45)  # =E)
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(0, self.main_engine.cursor.col)
        self.assertEqual(1, self.main_engine.cursor.row)


class TestLineBreakForEndOfTable(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.main_engine.cursor.set_position(38, 24)

        engine.set(self.key_code, 0x48)  # =H
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x45)  # =E
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(0, self.main_engine.cursor.col)
        self.assertEqual(0, self.main_engine.cursor.row)


class TestNormalClear(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act

        engine.set(self.key_code, 0x48)  # =H
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x08)  # =CLEAR
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(0, self.main_engine.char_memory.read(0, 0))
        self.assertEqual(0, self.main_engine.cursor.col)
        self.assertEqual(0, self.main_engine.cursor.row)


class TestClearMultipleChars(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        engine.set(self.key_code, 0x48)  # =H
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x45)  # =E
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x4C)  # =L
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x4C)  # =L
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x4F)  # =O
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x08)  # =CLEAR
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x08)  # =CLEAR
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(40, self.main_engine.char_memory.read(0, 0))
        self.assertEqual(37, self.main_engine.char_memory.read(0, 1))
        self.assertEqual(44, self.main_engine.char_memory.read(0, 2))
        self.assertEqual(0, self.main_engine.char_memory.read(0, 3))
        self.assertEqual(0, self.main_engine.char_memory.read(0, 4))

        self.assertEqual(0, self.main_engine.cursor.row)
        self.assertEqual(3, self.main_engine.cursor.col)


class TestLineBreakForStartOfRow(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        self.main_engine.cursor.set_position(1, 1)

        engine.set(self.key_code, 0x08)  # = CLEAR
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x08)  # = CLEAR
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(0, self.main_engine.char_memory.read(1, 0))
        self.assertEqual(0, self.main_engine.char_memory.read(0, 39))

        self.assertEqual(0, self.main_engine.cursor.row)
        self.assertEqual(39, self.main_engine.cursor.col)


class TestLineBreakStartOfTable(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        engine.set(self.key_code, 0x08)  # = CLEAR
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(0, self.main_engine.cursor.row)
        self.assertEqual(0, self.main_engine.cursor.col)


class TestNormalUseClearAllRandomInputs(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        engine.set(self.key_code, 0x48)  # = H
        self.main_engine.text_writer.user_write(engine, self.key_code)

        self.main_engine.cursor.set_position(0, 5)
        engine.set(self.key_code, 0x45)  # = E
        self.main_engine.text_writer.user_write(engine, self.key_code)

        self.main_engine.cursor.set_position(1, 3)
        engine.set(self.key_code, 0x4C)  # = L
        self.main_engine.text_writer.user_write(engine, self.key_code)

        self.main_engine.cursor.set_position(5, 20)
        engine.set(self.key_code, 0x4C)  # = L
        self.main_engine.text_writer.user_write(engine, self.key_code)

        self.main_engine.cursor.set_position(20, 20)
        engine.set(self.key_code, 0x4F)  # = O
        self.main_engine.text_writer.user_write(engine, self.key_code)

        engine.set(self.key_code, 0x7F)  # DELETE_ALL
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert
        self.assertEqual(0, self.main_engine.cursor.row)
        self.assertEqual(0, self.main_engine.cursor.col)
        self.assertEqual(0, self.main_engine.char_memory.read(0, 0))
        self.assertEqual(0, self.main_engine.char_memory.read(0, 5))
        self.assertEqual(0, self.main_engine.char_memory.read(1, 3))
        self.assertEqual(0, self.main_engine.char_memory.read(5, 20))
        self.assertEqual(0, self.main_engine.char_memory.read(20, 20))


class TestClearAllWithAllFieldsFilled(TextWriterTestBase):
    def the_testbench(self, engine: Engine) -> None:
        # Arrange & Act
        for row in range(self.main_engine.cursor.max_rows):
            for col in range(self.main_engine.cursor.max_columns):
                target_value = (row + col) % 63 + 1
                dynamic_signal = engine.define_local(f'dym_signal{row}_{col}', 6)
                engine.set(dynamic_signal, target_value)
                engine.sync()
                self.main_engine.char_memory.write(row, col, dynamic_signal)

        engine.set(self.key_code, 0x7F)  # DELETE_ALL
        self.main_engine.text_writer.user_write(engine, self.key_code)

        # Assert - after clear
        for row in range(self.main_engine.cursor.max_rows):
            for col in range(self.main_engine.cursor.max_columns):
                read_signal = self.main_engine.char_memory.read(row, col)

                self.assertEqual(read_signal, 0)
