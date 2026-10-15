from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.components.gpu import GPU
from commodore.components.text_writer import TextWriter
from commodore.tables.character_rom import CharacterRom
from commodore.tables.input_handler import InputHandler


class TestComponentIntegration(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')
        self.cursor = Cursor(engine)
        self.char_memory = CharacterMemory(engine)
        self.input_handler = InputHandler(engine)
        self.char_rom = CharacterRom(engine)
        self.text_writer = TextWriter(engine, self.cursor, self.char_memory, self.input_handler)
        self.gpu = GPU(engine, self.cursor, self.char_memory, self.char_rom)
        return engine

    def dut(self, engine: Engine) -> None:
        pass

    def the_testbench(self, engine: Engine) -> None:
        # ------Case1 - normal writing------
        # Arrange & Act
        self.text_writer.user_write(engine, 'A')
        self.gpu.set_coords_from_vga_as_cursor_pos(0, 0)
        char_signal = self.gpu.read_char_memory()
        local_value = self.char_rom.get_gpu_pixel_data(char_signal)
        test_signal_local = engine.define_local('TEST_LOCAL', 8, 0)
        engine.set(test_signal_local, local_value)

        expected_value = engine.define_local('EXPECTED_VALUE', 8, 0)
        engine.set(expected_value, 0x00183C667E666600)  # value for 'A'

        # Assert
        self.assertEqual(test_signal_local, expected_value)

        # ------Case2 - invalid input------
        # Arrange & Act
        self.text_writer.user_write(engine, '?')  # clear all
        self.text_writer.user_write(engine, 'Ä')
        self.gpu.set_coords_from_vga_as_cursor_pos(0, 0)
        C_2_char_signal = self.gpu.read_char_memory()
        C_2_local_value = self.char_rom.get_gpu_pixel_data(C_2_char_signal)
        C_2_test_signal_local = engine.define_local('C2_TEST_LOCAL', 8, 0)
        engine.set(C_2_test_signal_local, C_2_local_value)

        expected_value = engine.define_local('C2_EXPECTED_VALUE', 8, 0)
        engine.set(expected_value, 0x0000000000000000)  # value for 'A'

        # Assert
        self.assertEqual(test_signal_local, expected_value)
