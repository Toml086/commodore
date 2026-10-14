from nortl import Engine

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.tables.character_rom import CharacterRom


class GPU:
    def __init__(self, engine: Engine, cursor: Cursor, character_memory: CharacterMemory, character_rom: CharacterRom):
        self.engine = engine
        self.cursor = cursor
        self.character_memory = character_memory
        self.character_rom = character_rom

    def coords_from_vga(self, x_coordinate: int, y_coordinate: int) -> None:
        self.cursor.set_position(x_coordinate, y_coordinate)

    def read_char_memory(self) -> None:
        pos_row, pos_col = self.cursor.get_position()  # pos_row = index(0), pos_col = index(1)
        signal_in_pos = self.character_memory.read(pos_row, pos_col)

        signal_bitstream = self.character_rom.get_gpu_pixel_data(signal_in_pos)
