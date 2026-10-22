from nortl import Const, Engine

from components.character_memory import CharacterMemory
from components.cursor import Cursor
from components.tables.character_rom import CharacterRom
from components.tables.input_handler import InputHandler
from components.text_gpu import TextGPU
from components.text_writer import TextWriter
from components.vga.vga import VGA

MATRIX_WIDTH = 4
MATRIX_HEIGHT = 2


class MainEngine(Engine):
    def __init__(self, name: str):
        super().__init__(name)

        self.key_code = self.define_input('KEY_CODE', 8)
        self.key_valid = self.define_input('KEY_VALID', 1)

        self.char_memory = CharacterMemory(self, MATRIX_WIDTH, MATRIX_HEIGHT)
        self.cursor = Cursor(self, MATRIX_WIDTH, MATRIX_HEIGHT)
        self.char_rom = CharacterRom(self)
        self.text_gpu = TextGPU(self, self.char_memory, self.char_rom)
        self.input_handler = InputHandler(self)
        self.text_writer = TextWriter(self, self.cursor, self.char_memory, self.input_handler)
        self.vga = VGA(self, self.text_gpu)

    def build(self) -> None:
        self.sync()
        with self.fork('vga'):
            self.vga.run()

        with self.while_loop(Const(True)):
            self.wait_for(self.key_valid.rising())
            self.text_writer.user_write(self, self.key_code)

        with open('Commodore.sv', 'w') as fptr:
            fptr.write(self.to_verilog())


if __name__ == '__main__':
    engine = MainEngine('Commodore')
    engine.build()
