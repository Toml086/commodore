from pathlib import Path

from nortl import Engine
from nortl.renderer.json_renderer import JsonRenderer
from nortl.utils.test_wrapper import NoRTLTestBase

PROJECT_ROOT = Path(__file__).resolve().parent.parent
COVERAGE_DIR = PROJECT_ROOT / 'notebooks' / 'commodore' / 'build' / 'coverage'


class CoverageTestBase(NoRTLTestBase[Engine]):
    def callback_before_rendering(self, engine: Engine) -> Engine:
        engine.coverage.monitor_state_coverage()
        engine.coverage.monitor_transition_coverage()
        return engine

    def callback_after_execution(self, engine: Engine) -> None:
        engine.coverage.annotate(self.coverage_file)
        print(engine.coverage.state_coverage)
        print(engine.coverage.transition_coverage)

        COVERAGE_DIR.mkdir(parents=True, exist_ok=True)
        output = COVERAGE_DIR / f'{type(self).__name__}.json'
        output.write_text(JsonRenderer(engine, include_coverage=True).render())
