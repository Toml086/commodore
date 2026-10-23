from nortl import Engine, Segment
from nortl.core import Signal


@Segment
def wait_ticks(engine: Engine, counter: Signal, ticks: int) -> None:
    engine.set(counter, ticks - 1)
    engine.sync()
    with engine.while_loop(counter != 0):
        engine.set(counter, counter - 1)
        engine.sync()
