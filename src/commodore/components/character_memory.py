from nortl import Engine
from nortl.core import Signal


class CharacterMemory:
    def __init__(self, engine: Engine, character_bit_width: int = 6, width: int = 40, height: int = 25):
        self.engine = engine
        self.character_bit_width = character_bit_width
        self.matrix: list[list[Signal]] = [
            [self.engine.define_local(f'memory_{y:02}_{x:02}', character_bit_width, reset_value=0) for x in range(width)] for y in range(height)
        ]  # x:02, y:02 fills up with 0's --> number < 10 --> 5 -> 05

    # used in text_writer
    def write(self, row: int, col: int, value: Signal | int) -> None:
        if 0 <= row < len(self.matrix) and 0 <= col < len(self.matrix[row]):
            self.engine.set(self.matrix[row][col], value)

        else:
            raise IndexError('Out of bound')

    def read(self, row: int, col: int) -> Signal:
        if 0 <= row < len(self.matrix) and 0 <= col < len(self.matrix[row]):
            return self.matrix[row][col]
        else:
            raise IndexError('Out of bound')
