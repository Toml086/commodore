from nortl import Engine

from src.commodore.character_memory import CharacterMemory
from src.commodore.cursor import Cursor
from src.commodore.look_up_table import LookUpTable


class GPU:
    def __init__(self, engine: Engine, cursor: Cursor, character_memory: CharacterMemory, look_up_table: LookUpTable):
        self.engine = engine
        self.cursor = cursor
        self.character_memory = character_memory
        self.look_up_table = look_up_table

    def read_char_memory(self):
        pos_row = self.cursor.position()[0]
        pos_col = self.cursor.position()[1]
        signal_in_pos = self.character_memory.read(pos_row, pos_col)
