from nortl import Engine

from src.commodore.character_memory import CharacterMemory
from src.commodore.character_rom import CharacterRom
from src.commodore.cursor import Cursor
from src.commodore.look_up_table import LookUpTable


class GPU:
    def __init__(self, engine: Engine, cursor: Cursor, character_memory: CharacterMemory, look_up_table: LookUpTable, character_rom: CharacterRom):
        self.engine = engine
        self.cursor = cursor
        self.character_memory = character_memory
        self.look_up_table = look_up_table
        self.character_rom = character_rom

    def coords_from_vga(self, x_coordinate: int, y_coordinate: int) -> None:
        self.cursor.set_position(x_coordinate, y_coordinate)

    def read_char_memory(self) -> None:
        pos_row, pos_col = self.cursor.get_position()  # pos_row = index(0), pos_col = index(1)
        signal_in_pos = self.character_memory.read(pos_row, pos_col)

        signal_bitstream = self.character_rom.get_gpu_pixel_data(signal_in_pos)
