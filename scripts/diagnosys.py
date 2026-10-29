import json
from pathlib import Path
from typing import TypedDict, cast

PATH_REAL_ENGINE = Path('notebooks/commodore/build/commodore.json')
PATH_TEST_FILE = Path('notebooks/commodore/build/coverage/TestNormalWrite.json')


class WorkerDefinition(TypedDict):
    states: dict[str, object]


class EngineDefinition(TypedDict):
    workers: dict[str, WorkerDefinition]


class EngineFile(TypedDict):
    engine: EngineDefinition


def read_workers(path: Path) -> dict[str, WorkerDefinition]:
    engine_file = cast(EngineFile, json.loads(path.read_text()))
    return engine_file['engine']['workers']


real_workers = read_workers(PATH_REAL_ENGINE)
test_workers = read_workers(PATH_TEST_FILE)

real_state_counts = {name: len(definition['states']) for name, definition in real_workers.items()}
test_state_counts = {name: len(definition['states']) for name, definition in test_workers.items()}

print(f'Echte Engine: {len(real_workers)} Worker, größte nach State-Anzahl:')
largest_real_workers = sorted(((count, name) for name, count in real_state_counts.items()), reverse=True)[:10]
for count, name in largest_real_workers:
    print(f'  {name}: {count} States')

print(f'Test-Engine: {len(test_workers)} Worker:')
for name, count in test_state_counts.items():
    same_size_real_workers = [real for real, real_count in real_state_counts.items() if real_count == count]
    print(f'  {name}: {count} States, echte Worker gleicher Größe: {same_size_real_workers or "keine"}')
