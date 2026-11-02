from coverage_test_base import CoverageTestBase
from nortl import Engine

from commodore.components.uart.uart_timing import wait_ticks
from commodore.engine import MainEngine
from input_device.uart.data_sender import DataSender


class CommodoreTestBase(CoverageTestBase):
    expect_timeout = True

    def init_sequence(self) -> Engine:
        self.main_engine = MainEngine('my_engine')
        self.uart_recieve_signal = self.main_engine.signal
        # self.uart_recieve_signal.access_checker.disable_check('identical_rw')
        self.bit_ticks = self.main_engine.uart.data_reader.bit_ticks
        self.delay_counter = self.main_engine.define_local('TESTBASE_DELAY_COUNTER', 16, 0)

        self.data_sender = DataSender(self.main_engine, self.bit_ticks)
        self.data_sender.output = self.uart_recieve_signal

        self.key_code = self.main_engine.define_local('KEY_CODE', 8)
        self.data_source = self.main_engine.define_local('DATA_SOURCE', 6, 0)

        for signal in self.main_engine.signals.values():
            for check_name in ('identical_rw', 'exclusive_read', 'exclusive_write'):
                signal.access_checker.disable_check(check_name)

        return self.main_engine

    def dut(self, engine: Engine) -> None:
        self.main_engine.build()

    def start_uart(self) -> None:
        self.data_sender.idle()
        wait_ticks(self.main_engine, self.delay_counter, self.bit_ticks)

    def send_bytes(self, value: int, settle_ticks: int = 200) -> None:
        self.data_sender.send_data(self.main_engine, value)
        wait_ticks(self.main_engine, self.delay_counter, settle_ticks)
        self.reset_timeout()
