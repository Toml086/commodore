class Cursor:
    def __init__(self, max_columns: int = 40, max_rows: int = 25):
        self.max_columns = max_columns
        self.max_rows = max_rows
        self.col = 0
        self.row = 0

    def next(self) -> None:
        if self.col == self.max_columns - 1:
            self.col = 0
            self.row += 1
            if self.row == self.max_rows:
                self.row = 0

        else:
            self.col += 1

    def position(self) -> tuple[int, int]:
        return (self.row, self.col)
