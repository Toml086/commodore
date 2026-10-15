from nortl import Engine
from nortl.core import Signal

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.tables.character_rom import CharacterRom


class GPU:
    def __init__(self, engine: Engine, cursor: Cursor, character_memory: CharacterMemory, character_rom: CharacterRom):
        self.engine = engine
        self.cursor = cursor
        self.character_memory = character_memory
        self.character_rom = character_rom

    def set_coords_from_vga_as_cursor_pos(self, x_coordinate: int, y_coordinate: int) -> None:
        self.cursor.set_position(x_coordinate, y_coordinate)

    def read_char_memory(self) -> Signal:
        pos_row, pos_col = self.cursor.get_position()  # pos_row = index(0), pos_col = index(1)
        self.signal_in_pos = self.character_memory.read(pos_row, pos_col)
        return self.signal_in_pos

    def send_bitstream(self) -> None:
        signal_bitstream = self.character_rom.get_gpu_pixel_data(self.signal_in_pos)
