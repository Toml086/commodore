from nortl import All, Const, Engine, IfThenElse

from .objects import GraphicsObject

H_VISIBLE_AREA = 640
H_FRONT_PORCH = 16
H_SYNC = 96
H_BACK_PORCH = 48
H_LINES = H_VISIBLE_AREA + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH

V_VISIBLE_AREA = 480
V_FRONT_PORCH = 10
V_SYNC = 2
V_BACK_PORCH = 29
V_LINES = V_VISIBLE_AREA + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH


class VGA:
    """VGA timing generator for 640x480 @ 60 Hz.

    Runs two free-running counters, one per pixel within a line (``counter_h``)
    and one per line within a frame (``counter_v``), and derives the sync
    signals from them. Both counters wrap after their respective total,
    including front porch, sync pulse and back porch, so one full pass of
    ``counter_v`` corresponds to one frame. ``hsync`` and ``vsync`` are driven
    low while their counter is inside the sync pulse window and high otherwise.

    The RGB outputs are sampled every pixel from the attached
    :class:`~.objects.GraphicsObject`, which is queried with the current
    ``(counter_h, counter_v)`` position and acts as the pixel source.
    """

    def __init__(self, engine: Engine, go: GraphicsObject):
        self.engine = engine
        self.stash = go
        self.counter_v = engine.define_local('counter_v', (V_LINES - 1).bit_length(), reset_value=0)
        self.counter_h = engine.define_local('counter_h', (H_LINES - 1).bit_length(), reset_value=0)

        self.stop_output = engine.define_local('stop_vga', 1, 0)

        self.r = engine.define_output('red', 1)
        self.g = engine.define_output('green', 1)
        self.b = engine.define_output('blue', 1)
        self.vsync = engine.define_output('vsync', 1)
        self.hsync = engine.define_output('hsync', 1)

    def run(self) -> None:

        with self.engine.while_loop(Const(True)):
            last_pixel = self.counter_h == (H_LINES - 1)
            last_line = self.counter_v == (V_LINES - 1)

            self.engine.set(self.counter_h, IfThenElse(last_pixel, 0, self.counter_h + 1))
            self.engine.set_when(self.counter_v, {All(last_pixel, last_line): 0, last_pixel: self.counter_v + 1, 'default': self.counter_v})
            self.engine.set_when(
                self.hsync,
                {
                    self.counter_h < (H_VISIBLE_AREA + H_FRONT_PORCH): 1,
                    self.counter_h > (H_VISIBLE_AREA + H_FRONT_PORCH + H_SYNC - 1): 1,
                    'default': 0,
                },
            )
            self.engine.set_when(
                self.vsync,
                {
                    self.counter_v < (V_VISIBLE_AREA + V_FRONT_PORCH): 1,
                    self.counter_v > (V_VISIBLE_AREA + V_FRONT_PORCH + V_SYNC - 1): 1,
                    'default': 0,
                },
            )

            self.engine.set(self.r, (self.stash.color(self.counter_h, self.counter_v) & 0b100) != 0)
            self.engine.set(self.g, (self.stash.color(self.counter_h, self.counter_v) & 0b010) != 0)
            self.engine.set(self.b, (self.stash.color(self.counter_h, self.counter_v) & 0b001) != 0)

            with self.engine.condition(self.stop_output):
                pass
