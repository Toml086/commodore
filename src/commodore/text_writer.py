from nortl import Engine
from nortl.components import Timer
from nortl.renderer.verilog_utils.print_handlers import to_verilog

from commodore.sender_reciever.bit_stream_sender import BitStreamSender
from src.commodore.character_memory import CharacterMemory


class TextWriter(Engine):
    def __init__(self, module_name: str) -> None:
        self._fclk = int(1e6)
        self.timer = Timer(self, 24)
        self.character_memory = CharacterMemory(self)
