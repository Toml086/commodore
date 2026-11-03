from nortl import Const, Engine, IfThenElse, Volatile
from nortl.core import Signal
from nortl.core.protocols import Renderable


class CharacterMemory:
    def __init__(self, engine: Engine, width: int, height: int, character_bit_width: int = 6):
        self.engine = engine
        self.width = width
        self.height = height
        self.character_bit_width = character_bit_width
        self.matrix: list[list[Volatile[Signal]]] = [
            [Volatile(self.engine.define_local(f'memory_{y:02}_{x:02}', character_bit_width, reset_value=0)) for x in range(width)]
            for y in range(height)
        ]  # x:02, y:02 fills up with 0's --> number < 10 --> 5 -> 05

    # used in text_writer
    def write(self, row: int, col: int, value: Renderable | int) -> None:
        if 0 <= row < len(self.matrix) and 0 <= col < len(self.matrix[row]):
            self.engine.set(self.matrix[row][col], value)
            self.engine.sync()

        else:
            raise IndexError('Out of bound')

    def read(self, row: int, col: int) -> Volatile[Signal]:
        if 0 <= row < len(self.matrix) and 0 <= col < len(self.matrix[row]):
            return self.matrix[row][col]
        else:
            raise IndexError('Out of bound')

    def write_dynamic(self, row: Renderable, col: Renderable, value: Signal | int) -> None:
        for y, line in enumerate(self.matrix):
            for x, cell in enumerate(line):
                self.engine.set_when(cell, {(row == y) & (col == x): value})

    def read_dynamic(self, row: Renderable, col: Renderable) -> Renderable:
        result: Renderable = Const(0, self.character_bit_width)
        for y, line in enumerate(self.matrix):
            line_val: Renderable = Const(0, self.character_bit_width)
            for x, cell in enumerate(line):
                line_val = IfThenElse(col == x, cell, line_val)
            result = IfThenElse(row == y, line_val, result)
        return result

    # @Segment
    def clear_all(self) -> None:
        for line in self.matrix:
            for cell in line:
                self.engine.set(cell, 0)
