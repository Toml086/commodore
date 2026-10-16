from abc import ABCMeta, abstractmethod

from nortl import All, Any, Const, Engine, IfThenElse
from nortl.core.protocols import EngineProto, Operand, Renderable


class GraphicsObject(metaclass=ABCMeta):
    """Base class for objects on screen.

    The PPU itself is expected to query (x,y) coordinates to check if
    the object is on screen, which color it has and if there can be a collision
    """

    def __init__(self, engine: EngineProto) -> None:
        self.engine = engine
        self._type = Const(0, 4)  # Obj Type

    @abstractmethod
    def visible(self, x: Renderable, y: Renderable) -> Renderable:
        """Return if the pixel is visible."""

    @abstractmethod
    def color(self, x: Renderable, y: Renderable) -> Renderable:
        """Return color of the pixel."""

    @abstractmethod
    def tick(self) -> None:
        """State update for a time step."""

    def type(self, x: Renderable, y: Renderable) -> Renderable:
        return IfThenElse(self.visible(x, y), self._type, Const(0, 4))


class GraphicsStash(GraphicsObject):
    """Group of graphics objects that expose the same interface."""

    def __init__(self, engine: Engine) -> None:
        super().__init__(engine)

        self.graphics: list[GraphicsObject] = []

    def register(self, go: GraphicsObject) -> None:
        self.graphics.append(go)

    def visible(self, x: Renderable, y: Renderable) -> Renderable:
        list_of_visibilities = [go.visible(x, y) for go in self.graphics]
        return Any(*list_of_visibilities)

    def color(self, x: Renderable, y: Renderable) -> Renderable:
        ret: Renderable = Const(0)

        previous_visibilities: Renderable = Const(False)

        for go in self.graphics:
            ret = IfThenElse(All(~previous_visibilities, go.visible(x, y)), go.color(x, y), ret)
            previous_visibilities = previous_visibilities | go.visible(x, y)

        return ret

    def type(self, x: Renderable, y: Renderable) -> Renderable:
        ret: Renderable = Const(0)

        previous_visibilities: Renderable = Const(False)

        for go in self.graphics:
            ret = IfThenElse(All(~previous_visibilities, go.visible(x, y)), go.type(x, y), ret)
            previous_visibilities = previous_visibilities | go.visible(x, y)

        return ret

    def tick(self) -> None:
        for go in self.graphics:
            go.tick()


class Box(GraphicsObject):
    def __init__(self, engine: Engine, lx: Operand, ly: Operand, ux: Operand, uy: Operand, color: Operand, type: int = 0) -> None:
        super().__init__(engine)
        self.lx = lx
        self.ly = ly
        self.ux = ux
        self.uy = uy
        self.box_color = color
        self._type = Const(type, 4)

    def visible(self, x: Operand, y: Operand) -> Renderable:
        return All(x >= self.lx, y >= self.ly, x < self.ux, y < self.uy)  # type: ignore[arg-type]

    def tick(self) -> None:
        pass

    def color(self, x: Operand, y: Operand) -> Renderable:
        return IfThenElse(self.visible(x, y), self.box_color, Const(0))
