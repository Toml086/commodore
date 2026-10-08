from nortl import Engine
from nortl.core import Signal


class CharacterMemory:
    def __init__(self, engine: Engine, character_bit_width: int = 6, width: int = 40, height: int = 25):
        self.engine = engine
        self.character_bit_width = character_bit_width
        self.matrix: list[list[Signal]] = [
            [self.engine.define_local(f'memory_{x:02}_{y:02}', character_bit_width) for x in range(width)] for y in range(height)
        ]

    def write(row, col, char):
        pass

    def read(row, col) -> Signal:
        pass
