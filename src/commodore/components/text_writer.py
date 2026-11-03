from nortl import Engine
from nortl.core import Signal

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.components.tables.input_handler import InputHandler

KEY_BACKSPACE = 0x08
KEY_DELETE = 0x7F


class TextWriter:
    def __init__(self, engine: Engine, cursor: Cursor, character_memory: CharacterMemory, input_handler: InputHandler) -> None:
        self.engine = engine
        self.cursor = cursor
        self.character_memory = character_memory
        self.input_handler = input_handler

    def user_write(self, engine: Engine, key_code: Signal) -> None:
        engine.sync()
        with engine.condition(key_code == KEY_BACKSPACE):
            self.clear(engine)

        with engine.else_condition():
            with engine.condition(key_code == KEY_DELETE):
                self.clear_all(engine)

            with engine.else_condition():
                self.input_handler.handle_input(engine, key_code)
                engine.sync()
                self.character_memory.write_dynamic(self.cursor.row, self.cursor.col, self.input_handler.result)
                self.cursor.next()

    def clear(self, engine: Engine) -> None:
        self.cursor.prev()
        engine.sync()
        self.character_memory.write_dynamic(self.cursor.row, self.cursor.col, 0)

    def clear_all(self, engine: Engine) -> None:
        self.character_memory.clear_all()
        engine.sync()
        self.cursor.reset()
