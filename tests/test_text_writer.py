from commodore_test_base import CommodoreTestBase
from nortl import Engine

# test for text writer and cursor


class TestNormalWrite(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.start_uart()
        self.send_bytes(0x41)  # =A

        self.assertTrue(self.main_engine.cursor.col == 1)
        self.assertTrue(self.main_engine.cursor.row == 0)

        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 33)

        self.finish_simulation()


class TestWriteMultipleChars(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.start_uart()
        self.send_bytes(0x42)  # =B
        self.send_bytes(0x31)  # =1
        self.send_bytes(0x4F)  # =O

        self.assertTrue(self.main_engine.cursor.col == 3)

        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 34)
        self.assertTrue(self.main_engine.char_memory.read(0, 1) == 17)
        self.assertTrue(self.main_engine.char_memory.read(0, 2) == 47)

        self.finish_simulation()


class TestLineBreakForEndOfRow(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.main_engine.cursor.set_position(38, 0)

        self.start_uart()

        self.send_bytes(0x48)  # =H, column 38
        self.send_bytes(0x45)  # =E, column 39

        self.assertTrue(self.main_engine.cursor.col == 0)
        self.assertTrue(self.main_engine.cursor.row == 1)

        self.finish_simulation()


class TestLineBreakForEndOfTable(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.main_engine.cursor.set_position(38, 24)

        self.start_uart()

        self.send_bytes(0x48)  # =H, row 24, column 38
        self.send_bytes(0x45)  # =E, row 24, column 39

        self.assertTrue(self.main_engine.cursor.col == 0)
        self.assertTrue(self.main_engine.cursor.row == 0)

        self.finish_simulation()


class TestNormalClear(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.start_uart()
        self.send_bytes(0x48)  # =H
        self.send_bytes(0x08)  # =CLEAR

        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 0)
        self.assertTrue(self.main_engine.cursor.col == 0)
        self.assertTrue(self.main_engine.cursor.row == 0)

        self.finish_simulation()


class TestClearMultipleChars(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.start_uart()
        self.send_bytes(0x48)  # =H
        self.send_bytes(0x45)  # =E
        self.send_bytes(0x4C)  # =L
        self.send_bytes(0x4C)  # =L
        self.send_bytes(0x4F)  # =O
        self.send_bytes(0x08)  # =CLEAR
        self.send_bytes(0x08)  # =CLEAR

        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 40)
        self.assertTrue(self.main_engine.char_memory.read(0, 1) == 37)
        self.assertTrue(self.main_engine.char_memory.read(0, 2) == 44)
        self.assertTrue(self.main_engine.char_memory.read(0, 3) == 0)
        self.assertTrue(self.main_engine.char_memory.read(0, 4) == 0)

        self.assertTrue(self.main_engine.cursor.row == 0)
        self.assertTrue(self.main_engine.cursor.col == 3)

        self.finish_simulation()


class TestLineBreakForStartOfRow(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.main_engine.cursor.set_position(1, 1)
        self.main_engine.char_memory.write(1, 0, 33)
        self.main_engine.char_memory.write(0, 39, 33)

        self.start_uart()

        self.send_bytes(0x08)  # =CLEAR, clears row 1, column 0
        self.send_bytes(0x08)  # =CLEAR, jumps to row 0, column 39 and clears it

        self.assertTrue(self.main_engine.char_memory.read(1, 0) == 0)
        self.assertTrue(self.main_engine.char_memory.read(0, 39) == 0)

        self.assertTrue(self.main_engine.cursor.row == 0)
        self.assertTrue(self.main_engine.cursor.col == 39)

        self.finish_simulation()


class TestLineBreakStartOfTable(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.start_uart()
        self.send_bytes(0x08)  # =CLEAR

        self.assertTrue(self.main_engine.cursor.row == 0)
        self.assertTrue(self.main_engine.cursor.col == 0)

        self.finish_simulation()


class TestNormalUseClearAllRandomInputs(CommodoreTestBase):
    def the_testbench(self, engine: Engine) -> None:
        self.start_uart()

        repeat_counter = engine.define_local('REPEAT_COUNTER', 16, 0)
        engine.set(repeat_counter, 0)
        with engine.while_loop(repeat_counter != 85):
            self.send_bytes(0x41)  # =A, two full rows and five cells of row 2
            engine.set(repeat_counter, repeat_counter + 1)

        self.assertTrue(self.main_engine.char_memory.read(2, 4) == 33)

        self.send_bytes(0x7F, settle_ticks=200)  # DELETE_ALL

        self.assertTrue(self.main_engine.cursor.row == 0)
        self.assertTrue(self.main_engine.cursor.col == 0)
        self.assertTrue(self.main_engine.char_memory.read(0, 0) == 0)
        # self.assertTrue(self.main_engine.char_memory.read(0, 39) == 0)
        self.assertTrue(self.main_engine.char_memory.read(1, 0) == 0)
        # self.assertTrue(self.main_engine.char_memory.read(1, 39) == 0)
        # self.assertTrue(self.main_engine.char_memory.read(2, 4) == 0)

        self.finish_simulation()
