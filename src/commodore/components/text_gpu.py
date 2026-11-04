from nortl import All, Const, Engine, IfThenElse
from nortl.core.protocols import Renderable

from commodore.components.character_memory import CharacterMemory
from commodore.components.tables.character_rom import CharacterRom
from commodore.components.vga.objects import GraphicsObject


class TextGPU(GraphicsObject):
    def __init__(
        self, engine: Engine, character_memory: CharacterMemory, character_rom: CharacterRom, colour_fg: int = 0b111, colour_bg: int = 0b000
    ):
        super().__init__(engine)
        self.character_memory = character_memory
        self.character_rom = character_rom
        self.colour_fg = Const(colour_fg, 3)
        self.colour_bg = Const(colour_bg, 3)

        # Pipeline register
        self.next_character = engine.define_local('GPU_CHAR_Q', character_memory.character_bit_width, 0)
        self.next_glyph_row = engine.define_local('GPU_ROWBITS_NEXT', 8, 0)
        self.current_glyph_row = engine.define_local('GPU_ROWBITS', 8, 0)

    def visible(self, x: Renderable, y: Renderable) -> Renderable:
        return All(x < 640, y < 400)

    def update(self, x: Renderable, y: Renderable, next_line: Renderable) -> None:
        pixel_in_cell = x & 0b1111
        current_col = x >> 4

        in_last_col = x >= 624
        next_col = IfThenElse(in_last_col, 0, current_col + 1)
        prefetch_y = IfThenElse(in_last_col, next_line, y)
        prefetch_row = prefetch_y >> 4
        glyph_row_idx = (prefetch_y >> 1) & 0b111

        self.engine.set_when(
            self.next_character,
            {pixel_in_cell == 2: self.character_memory.read_dynamic(prefetch_row, next_col)},
        )

        glyph = self.character_rom.get_gpu_pixel_data(self.next_character)
        byte_shift = (~glyph_row_idx & 0b111) << 3
        self.engine.set_when(
            self.next_glyph_row,
            {pixel_in_cell == 4: (glyph >> byte_shift) & 0xFF},
        )

        self.engine.set_when(
            self.current_glyph_row,
            {pixel_in_cell == 0b1111: self.next_glyph_row},
        )

    def color(self, x: Renderable, y: Renderable) -> Renderable:
        bit_idx = ~(x >> 1) & 0b111
        pixel_on = ((self.current_glyph_row >> bit_idx) & 1) != 0

        text_pixel = IfThenElse(pixel_on, self.colour_fg, self.colour_bg)
        return IfThenElse(self.visible(x, y), text_pixel, Const(0, 3))

    def tick(self) -> None:
        pass
