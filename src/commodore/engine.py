from nortl import Engine

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.components.tables.character_rom import CharacterRom
from commodore.components.tables.input_handler import InputHandler
from commodore.components.text_gpu import TextGPU
from commodore.components.text_writer import TextWriter
from commodore.components.uart.uart import UART
from commodore.components.vga.vga import VGA

# FIXME
MATRIX_WIDTH = 2
MATRIX_HEIGHT = 2
# FIXME


class MainEngine(Engine):
    def __init__(self, name: str):
        super().__init__(name)

        self.char_memory = CharacterMemory(self, MATRIX_WIDTH, MATRIX_HEIGHT)
        self.cursor = Cursor(self, MATRIX_WIDTH, MATRIX_HEIGHT)
        self.char_rom = CharacterRom(self)
        self.text_gpu = TextGPU(self, self.char_memory, self.char_rom)
        self.input_handler = InputHandler(self)
        self.text_writer = TextWriter(self, self.cursor, self.char_memory, self.input_handler)
        self.vga = VGA(self, self.text_gpu)
        self.signal = self.define_input('UART_RX', 1)
        self.uart = UART(self, self.text_writer, self.signal)

    def build(self) -> None:
        self.sync()
        with self.fork('vga'):
            self.current_worker._name = 'VGA_WORKER'
            self.vga.run()

        self.uart.run()

    def export_verilog(self) -> None:
        with open('Commodore.sv', 'w') as fptr:
            fptr.write(self.to_verilog())


if __name__ == '__main__':
    engine = MainEngine('Commodore')
    engine.build()
    engine.export_verilog()
