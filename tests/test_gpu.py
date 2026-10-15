from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.components.gpu import GPU
from commodore.tables.character_rom import CharacterRom

# test for gpu and parts of cursor


class TestGPU(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')

        self.cursor = Cursor(engine)
        self.char_memory = CharacterMemory(engine)
        self.char_rom = CharacterRom(engine)
        self.gpu = GPU(engine, self.cursor, self.char_memory, self.char_rom)

        return engine

    def dut(self, engine: Engine) -> None:
        pass

    def the_testbench(self, engine: Engine) -> None:
        # ------Case1 - set coords from vga correctly------
        # Arrange & Act
        self.gpu.set_coords_from_vga_as_cursor_pos(10, 20)
        first_pos_row, first_pos_col = self.cursor.get_position()
        self.gpu.set_coords_from_vga_as_cursor_pos(20, 38)

        # Assert
        assert (first_pos_row, first_pos_col) == (10, 20)
        assert (self.cursor.get_position()) == (20, 38)

        # ------Case2 - set coords from vga with wrong row index------
        # Arrange & Act
        self.cursor.set_position(10, 20)
        self.gpu.set_coords_from_vga_as_cursor_pos(25, 10)

        # Assert
        assert (self.cursor.get_position()) == (0, 0)

        # ------Case2 - set coords from vga with wrong col index------
        # Arrange & Act
        self.cursor.set_position(10, 20)
        self.gpu.set_coords_from_vga_as_cursor_pos(10, 40)

        # Assert
        assert (self.cursor.get_position()) == (0, 0)
