from nortl import Engine
from nortl.core import Signal


class Cursor:
    def __init__(self, engine: Engine, max_columns: int, max_rows: int):
        self.engine = engine
        self.max_columns = max_columns
        self.max_rows = max_rows
        self.col: Signal = engine.define_local('col_cursor', (max_columns - 1).bit_length(), 0)
        self.row: Signal = engine.define_local('row_cursor', (max_rows - 1).bit_length(), 0)

    def get_position(self) -> tuple[Signal, Signal]:
        return (self.col, self.row)

    def set_position(self, col: int, row: int) -> None:
        self.engine.set(self.col, col)
        self.engine.set(self.row, row)

    def reset(self) -> None:
        self.engine.set(self.col, 0)
        self.engine.sync()
        self.engine.set(self.row, 0)

    def next(self) -> None:
        with self.engine.condition(self.col == self.max_columns - 1):
            self.engine.set(self.col, 0)
            with self.engine.condition(self.row == self.max_rows - 1):
                self.engine.set(self.row, 0)

            with self.engine.else_condition():
                self.engine.set(self.row, self.row + 1)

        with self.engine.else_condition():
            self.engine.set(self.col, self.col + 1)

    def prev(self) -> None:
        with self.engine.condition(self.col == 0):
            with self.engine.condition(self.row != 0):
                self.engine.set(self.col, self.max_columns - 1)
                self.engine.sync()
                self.engine.set(self.row, self.row - 1)
            with self.engine.else_condition():
                self.engine.set(self.col, 0)
                self.engine.set(self.row, 0)
        with self.engine.else_condition():
            self.engine.set(self.col, self.col - 1)
