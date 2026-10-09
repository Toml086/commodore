from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from src.commodore.character_memory import CharacterMemory


class TestNormalUse(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:

        engine = CharacterMemory('test_engine')

        self.char_memory = CharacterMemory(engine, character_bit_width=6, width=40, height=25)
        self.data_source = engine.define_local('data_source', 6, 0)

        return engine

    def dut(self, engine: Engine) -> None:
        pass

    def the_testbench(self, engine: Engine) -> None:
        # Case1 - initial state
        engine.sync()
        cell_0_0 = self.char_memory.read(0, 0)
        self.assertEqual(cell_0_0, 0)

        # Case2 - read and write
        engine.sync()

        self.char_memory.write(1, 1, self.data_source)
        engine.sync()
        read_signal = self.char_memory.read(1, 1)
        engine.sync()

        self.assertEqual(self.data_source, read_signal)

        # Case3 - test index out of bound errors
        engine.sync()
        try:
            self.char_memory.write(0, 40, self.data_source)
            self.assertTrue(False)
        except IndexError:
            self.assertTrue(True)

        engine.sync()

        # Case4 - fill all fields
        for row in range(25):
            for col in range(40):
                target_value = (row + col) % 64
                dynamic_signal = engine.define_local(f'dyn_sig_{row}_{col}', 6, reset_value=target_value)
                engine.sync()
                self.char_memory.write(row, col, dynamic_signal)
                engine.sync()

        for row in range(25):
            for col in range(40):
                expected_value = (row + col) % 64

                read_signal = self.char_memory.read(row, col)

                self.assertEqual(read_signal, expected_value)
