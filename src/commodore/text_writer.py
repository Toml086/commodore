from nortl import Engine
from nortl.core import Signal

from commodore.character_memory import CharacterMemory
from commodore.cursor import Cursor
from commodore.input_handler import InputHandler


class TextWriter:
    def __init__(
        self,
        engine: Engine,
        module_name: str,
        cursor: Cursor,
        character_memory: CharacterMemory,
        input_handler: InputHandler,
    ) -> None:
        self.engine = engine
        self.module_name = module_name
        self.cursor = cursor
        self.character_memory = character_memory
        self.input_handler = input_handler

    def user_write(self, engine: Engine, char_input: str) -> None:
        engine.sync()
        handled_input = self.input_handler.handle_input(char_input)

        if handled_input == 1:  # change + test!!!! current -> !
            self.clear(engine)
            return

        elif handled_input == 31:  # change + test!!!!  current -> ?
            self.clear_all(engine)
            return

        else:
            writing_pos_row, writing_pos_col = self.cursor.get_position()  # pos_row = index(0), pos_col = index(1)
            self.character_memory.write(writing_pos_row, writing_pos_col, handled_input)
            self.cursor.next()

    def clear(self, engine: Engine) -> None:
        try:
            self.cursor.prev()
        except IndexError:
            return
        writing_pos_row, writing_pos_col = self.cursor.get_position()  # pos_row = index(0), pos_col = index(1)
        self.character_memory.write(writing_pos_row, writing_pos_col, 0)

    def clear_all(self, engine: Engine) -> None:
        while True:
            try:
                self.cursor.prev()
            except IndexError:
                break
            writing_pos_row, writing_pos_col = self.cursor.get_position()
            self.character_memory.write(writing_pos_row, writing_pos_col, 0)
