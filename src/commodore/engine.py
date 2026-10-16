from nortl import Engine

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.components.text_gpu import TextGPU
from commodore.components.text_writer import TextWriter
from commodore.components.vga.objects import GraphicsObject
from commodore.components.vga.vga import VGA
from commodore.tables.character_rom import CharacterRom
from commodore.tables.input_handler import InputHandler


class MainEngine:
    def __init__(
        self,
        engine: Engine,
        char_memory: CharacterMemory,
        cursor: Cursor,
        text_gpu: TextGPU,
        text_writer: TextWriter,
        vga: VGA,
        char_rom: CharacterRom,
        input_handler: InputHandler,
    ):
        self.engine = engine
        self.char_memory = char_memory
        self.cursor = cursor
        self.text_gpu = text_gpu
        self.text_writer = text_writer
        self.vga = vga
        self.char_rom = char_rom
        self.input_handler = input_handler
