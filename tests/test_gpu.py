from nortl import Engine
from nortl.utils.test_wrapper import NoRTLTestBase

from commodore.components.character_memory import CharacterMemory
from commodore.components.cursor import Cursor
from commodore.tables.character_rom import CharacterRom


class TestGPU(NoRTLTestBase[Engine]):
    def init_sequence(self) -> Engine:
        engine = Engine('my_engine')

        self.cursor = Cursor(engine)
        self.char_memory = CharacterMemory(engine)
        self.char_rom = CharacterRom(engine)

        return engine

    def dut(self, engine: Engine) -> None:
        pass


    def the_testbench(self, engine: Engine) -> None:
