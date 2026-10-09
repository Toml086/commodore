from nortl import Engine
from nortl.components import Timer
from nortl.core.manager.signal_manager import SignalManager
from nortl.renderer.verilog_utils.print_handlers import to_verilog

from commodore.character_memory.CharacterMemory import CharacterMemory
from commodore.cursor.Cursor import Cursor
from commodore.sender_reciever.bit_stream_sender import BitStreamSender
from src.commodore.character_memory import CharacterMemory


class TextWriter:
    def __init__(self, engine: Engine, module_name: str, cursor: Cursor, character_memory: CharacterMemory) -> None:
        self.engine = engine
        self.character_memory = CharacterMemory(self)
        self.module_name = module_name
        self.cursor = cursor
        self.character_memory = self.character_memory

    def user_write(self, engine: Engine) -> Signal:
        user_input = input('Enter input')
        engine.define_input('USER_INPUT', 6)
        writing_pos_row = self.cursor.position()[0]
        writing_pos_col = self.cursor.position()[1]
        self.character_memory.write(writing_pos_row, writing_pos_col, user_input)

        self.cursor.next()
