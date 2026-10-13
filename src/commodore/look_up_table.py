from nortl import Engine
from nortl.components.lookup_table import LookupTable
from nortl.core import Signal


class LookUpTable:
    def __init__(self, engine: Engine):
        self.engine = engine

        self.table = LookupTable(
            [
                ' ',  # 0
                '!',  # 1
                '"',  # 2
                ' ',  # 3
                ' ',  # 4
                '%',  # 5
                '&',  # 6
                "'",  # 7
                '(',  # 8
                ')',  # 9
                '*',  # 10
                '+',  # 11
                ',',  # 12
                '-',  # 13
                '.',  # 14
                '/',  # 15
                '0',  # 16
                '1',  # 17
                '2',  # 18
                '3',  # 19
                '4',  # 20
                '5',  # 21
                '6',  # 22
                '7',  # 23
                '8',  # 24
                '9',  # 25
                ':',  # 26
                ';',  # 27
                '<',  # 28
                '=',  # 29
                '>',  # 30
                '?',  # 31
                '@',  # 32
                'A',  # 33
                'B',  # 34
                'C',  # 35
                'D',  # 36
                'E',  # 37
                'F',  # 38
                'G',  # 39
                'H',  # 40
                'I',  # 41
                'J',  # 42
                'K',  # 43
                'L',  # 44
                'M',  # 45
                'N',  # 46
                'O',  # 47
                'P',  # 48
                'Q',  # 49
                'R',  # 50
                'S',  # 51
                'T',  # 52
                'U',  # 53
                'V',  # 54
                'W',  # 55
                'X',  # 56
                'Y',  # 57
                'Z',  # 58
                '[',  # 59
                '?',  # 60
                ']',  # 61
                '?',  # 62
                '?',
            ],
            default=0,
        )

    def read(self, char: str) -> Signal:
        index = self.table.read(char)
        local = self.engine.define_local('INDEX', 6)
        self.engine.set(local, index)
        return local
