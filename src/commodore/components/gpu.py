from nortl import Concat, Engine
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

    def read_framebuffer(self) -> None:
        last_row = -1
        last_col = -1
        for y in range(768):
            for x in range(1024):
                row = y // 8
                col = x // 8
                row_offset = y % 8
                col_offset = x % 8

                if row != last_row or col != last_col:
                    self.signal_in_pos = self.character_memory.read(y, x)
                    char_buffer = self.character_rom.get_gpu_pixel_data(self.signal_in_pos)

                pixel_value = char_buffer[col_offset + 8 * row_offset]

                # Send the pixel value to VGA output
                self.engine.set(vga_out, Concat(pixel_value, pixel_value, pixel_value))
                self.engine.sync()

        for row in range(25):
            for row_offset in range(8):
                for col in range(40):
                    self.signal_in_pos = self.character_memory.read(y, x)
                    char_buffer = self.character_rom.get_gpu_pixel_data(self.signal_in_pos)

                    for col_offset in range(8):
                        pixel_value = char_buffer[col_offset + 8 * row_offset]

                        # Send the pixel value to VGA output
                        self.engine.set(vga_out, Concat(pixel_value, pixel_value, pixel_value))
                        self.engine.sync()
