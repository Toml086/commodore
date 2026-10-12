from nortl import Engine

from commodore.cursor import Cursor
from src.commodore.character_memory import CharacterMemory
from src.commodore.look_up_table import LookUpTable


class TextWriter:
    def __init__(self, engine: Engine, module_name: str, cursor: Cursor, character_memory: CharacterMemory, look_up_table: LookUpTable) -> None:
        self.engine = engine
        self.module_name = module_name
        self.cursor = cursor
        self.character_memory = character_memory
        self.look_up_table = look_up_table

    def user_write(self, engine: Engine) -> None:
        char_input = input('Enter input')

        if char_input == '[DEL]':
            self.clear()
            return

        else:
            signal_input = engine.define_input('USER_INPUT', 6)
            engine.set(signal_input, self.look_up_table.read(signal_input))  # input in LUT index
            writing_pos_row, writing_pos_col = self.cursor.position()  # pos_row = index(0), pos_col = index(1)
            self.character_memory.write(writing_pos_row, writing_pos_col, signal_input)
            self.cursor.next()

    def clear(self, engine: Engine) -> None:
        zero_signal = engine.define_input('ZERO_INPUT', 6)
        empty_signal = engine.set(zero_signal, 0)
        writing_pos_row, writing_pos_col = self.cursor.position()  # pos_row = index(0), pos_col = index(1)
        self.character_memory.write(writing_pos_row, writing_pos_col, empty_signal)

        self.cursor.prev()
