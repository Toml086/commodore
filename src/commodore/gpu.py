from nortl import Engine

from src.commodore.character_memory import CharacterMemory
from src.commodore.look_up_table import LookUpTable
from src.commodore.text_writer import TextWriter


class GPU:
    def __init__(self, engine: Engine, character_memory: CharacterMemory):
        self.engine = engine
        self.character_memory = character_memory
