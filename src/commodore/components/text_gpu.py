from nortl import All, Const, Engine, IfThenElse
from nortl.core.protocols import Renderable

from commodore.components.character_memory import CharacterMemory
from commodore.components.vga.objects import GraphicsObject
from commodore.tables.character_rom import CharacterRom


class TextGPU(GraphicsObject):
    def __init__(
        self, engine: Engine, character_memory: CharacterMemory, character_rom: CharacterRom, colour_fg: int = 0b111, colour_bg: int = 0b000
    ):
        super().__init__(engine)
        self.character_memory = character_memory
        self.character_rom = character_rom
        self.colour_fg = Const(colour_fg, 3)
        self.colour_bg = Const(colour_bg, 3)

    def visible(self, x: Renderable, y: Renderable) -> Renderable:
        return All(x < 640, y < 400)

    def color(self, x: Renderable, y: Renderable) -> Renderable:
        px, py = x >> 1, y >> 1
        col, col_off = px >> 3, px & 0b111
        row, row_off = py >> 3, py & 0b111

        char = self.character_memory.read_dynamic(row, col)
        glyph = self.character_rom.get_gpu_pixel_data(char)

        bit_index = ((~row_off & 0b111) << 3) | (~col_off & 0b111)
        pixel_on = ((glyph >> bit_index) & 1) != 0

        text_pixel = IfThenElse(pixel_on, self.colour_fg, self.colour_bg)
        return IfThenElse(self.visible(x, y), text_pixel, Const(0, 3))

    def tick(self) -> None:
        pass
