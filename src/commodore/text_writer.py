from nortl import Engine

from commodore.cursor import Cursor
from src.commodore.character_memory import CharacterMemory
from src.commodore.input_handler import InputHandler
from src.commodore.look_up_table import LookUpTable


class TextWriter:
    def __init__(
        self,
        engine: Engine,
        module_name: str,
        cursor: Cursor,
        character_memory: CharacterMemory,
        look_up_table: LookUpTable,
        input_handler: InputHandler,
    ) -> None:
        self.engine = engine
        self.module_name = module_name
        self.cursor = cursor
        self.character_memory = character_memory
        self.look_up_table = look_up_table
        self.input_handler = input_handler

    def user_write(self, engine: Engine) -> None:
        char_input = input('Enter input')
        handled_input = self.input_handler.handle_input(char_input)

        if handled_input == '[xxxxxx]':
            self.clear()
            return

        elif handled_input == '[xxxxxx]':
            self.clear_all()
            return

        else:
            signal_local = engine.define_input('USER_LOCAL', 6)
            engine.set(signal_local, self.look_up_table.read(signal_local))  # input in LUT index
            writing_pos_row, writing_pos_col = self.cursor.get_position()  # pos_row = index(0), pos_col = index(1)
            self.character_memory.write(writing_pos_row, writing_pos_col, signal_local)
            self.cursor.next()

    def clear(self, engine: Engine) -> None:
        zero_signal = engine.define_input('ZERO_INPUT', 6)
        empty_signal = engine.set(zero_signal, 0)
        writing_pos_row, writing_pos_col = self.cursor.get_position()  # pos_row = index(0), pos_col = index(1)
        self.character_memory.write(writing_pos_row, writing_pos_col, empty_signal)

        self.cursor.prev()

    def clear_all(self, engine: Engine) -> None:
        zero_signal = engine.define_input('ZERO_INPUT', 6)
        empty_signal = engine.set(zero_signal, 0)
        while True:
            writing_pos_row, writing_pos_col = self.cursor.get_position()
            if writing_pos_col == 0 & writing_pos_col == 0:
                return
            else:
                self.character_memory.write(writing_pos_row, writing_pos_col, empty_signal)
                self.cursor.prev()
