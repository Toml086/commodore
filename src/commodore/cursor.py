from nortl import Engine


class Cursor:
    def __init__(self, engine: Engine, max_columns: int = 40, max_rows: int = 25):
        self.engine = engine
        self.max_columns = max_columns
        self.max_rows = max_rows
        self.col = 0
        self.row = 0

    def get_position(self) -> tuple[int, int]:
        return (self.row, self.col)

    def set_position(self, row: int, col: int) -> None:
        self.row = row
        self.col = col

    def next(self) -> None:
        if self.col == self.max_columns - 1 and self.row == self.max_rows - 1:
            self.row = 0
            self.col = 0

        elif self.col == self.max_columns - 1:
            self.col = 0
            self.row += 1

        else:
            self.col += 1

    def prev(self) -> None:
        if self.col == 0 and self.row == 0:
            raise IndexError('Out of bound')

        elif self.col == 0:
            self.col = self.max_columns - 1
            self.row -= 1

        else:
            self.col -= 1
