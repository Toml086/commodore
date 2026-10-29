import hashlib
import json
from pathlib import Path
from typing import TypedDict, cast

PATH_REAL_ENGINE = Path('notebooks/commodore/build/commodore.json')
DIRECTORY_TEST_RESULTS = Path('notebooks/commodore/build/coverage')
PATH_OUTPUT = Path('notebooks/commodore/build/commodore_coverage.json')


class TransitionCoverage(TypedDict):
    coverage: bool


class StateCoverage(TypedDict):
    coverage: bool
    transitions: list[TransitionCoverage]


class WorkerCoverage(TypedDict):
    states: dict[str, StateCoverage]


class CoverageOverlay(TypedDict):
    name: str
    start_time: str | None
    workers: dict[str, WorkerCoverage]


class StateDefinition(TypedDict):
    name: str
    transitions: list[object]


class WorkerDefinition(TypedDict):
    name: str
    states: dict[str, StateDefinition]


class EngineDefinition(TypedDict):
    name: str
    workers: dict[str, WorkerDefinition]


class EngineFile(TypedDict):
    sha256sum: str
    version: str
    engine: EngineDefinition
    coverage_overlays: dict[str, CoverageOverlay]


def read_engine_file(path: Path) -> EngineFile:
    return cast(EngineFile, json.loads(path.read_text()))


def create_worker_fingerprint(worker_name: str, worker_definition: WorkerDefinition) -> str:
    definition_without_name = dict(worker_definition)
    definition_without_name.pop('name', None)

    definition_as_text = json.dumps(definition_without_name, sort_keys=True)
    definition_as_text = definition_as_text.replace(f'{worker_name}_', '')

    return hashlib.sha256(definition_as_text.encode()).hexdigest()


def create_uncovered_worker_coverage(real_worker_definition: WorkerDefinition) -> WorkerCoverage:
    uncovered_states: dict[str, StateCoverage] = {}
    for state_name, state_definition in real_worker_definition['states'].items():
        uncovered_transitions: list[TransitionCoverage] = [{'coverage': False} for _ in state_definition['transitions']]
        uncovered_states[state_name] = {'coverage': False, 'transitions': uncovered_transitions}
    return {'states': uncovered_states}


def combine_worker_coverage(first_coverage: WorkerCoverage, second_coverage: WorkerCoverage) -> WorkerCoverage:
    combined_states: dict[str, StateCoverage] = {}
    for state_name, first_state in first_coverage['states'].items():
        second_state = second_coverage['states'][state_name]

        combined_transitions: list[TransitionCoverage] = []
        for first_transition, second_transition in zip(first_state['transitions'], second_state['transitions']):
            combined_transitions.append({'coverage': first_transition['coverage'] or second_transition['coverage']})

        combined_states[state_name] = {
            'coverage': first_state['coverage'] or second_state['coverage'],
            'transitions': combined_transitions,
        }
    return {'states': combined_states}


def translate_test_worker_coverage(
    real_worker_definition: WorkerDefinition,
    test_worker_definition: WorkerDefinition,
    test_worker_coverage: WorkerCoverage,
) -> WorkerCoverage:
    translated_states: dict[str, StateCoverage] = {}
    for real_state_name, test_state_name in zip(real_worker_definition['states'], test_worker_definition['states']):
        translated_states[real_state_name] = test_worker_coverage['states'][test_state_name]
    return {'states': translated_states}


def main() -> None:
    real_engine = read_engine_file(PATH_REAL_ENGINE)
    real_workers = real_engine['engine']['workers']

    real_worker_names_by_fingerprint: dict[str, str] = {}
    for real_worker_name, real_worker_definition in real_workers.items():
        fingerprint = create_worker_fingerprint(real_worker_name, real_worker_definition)
        real_worker_names_by_fingerprint[fingerprint] = real_worker_name

    overlays_per_test: dict[str, CoverageOverlay] = {}
    coverage_over_all_tests: dict[str, WorkerCoverage] = {
        real_worker_name: create_uncovered_worker_coverage(real_worker_definition)
        for real_worker_name, real_worker_definition in real_workers.items()
    }

    for test_file in sorted(DIRECTORY_TEST_RESULTS.glob('*.json')):
        test_data = read_engine_file(test_file)
        test_workers = test_data['engine']['workers']

        if not test_data['coverage_overlays']:
            print(f'{test_file.stem}: skipped (no coverage-data included)')
            continue
        test_overlay = next(iter(test_data['coverage_overlays'].values()))

        test_worker_names_by_real_worker_name: dict[str, str] = {}
        for test_worker_name, test_worker_definition in test_workers.items():
            fingerprint = create_worker_fingerprint(test_worker_name, test_worker_definition)
            matching_real_worker_name = real_worker_names_by_fingerprint.get(fingerprint)
            if matching_real_worker_name is not None:
                test_worker_names_by_real_worker_name[matching_real_worker_name] = test_worker_name

        coverage_of_this_test: dict[str, WorkerCoverage] = {}
        for real_worker_name, real_worker_definition in real_workers.items():
            matching_test_worker_name = test_worker_names_by_real_worker_name.get(real_worker_name)
            if matching_test_worker_name is None:
                coverage_of_this_test[real_worker_name] = create_uncovered_worker_coverage(real_worker_definition)
            else:
                coverage_of_this_test[real_worker_name] = translate_test_worker_coverage(
                    real_worker_definition,
                    test_workers[matching_test_worker_name],
                    test_overlay['workers'][matching_test_worker_name],
                )

            coverage_over_all_tests[real_worker_name] = combine_worker_coverage(
                coverage_over_all_tests[real_worker_name],
                coverage_of_this_test[real_worker_name],
            )

        overlays_per_test[test_file.stem] = {
            'name': test_file.stem,
            'start_time': test_overlay['start_time'],
            'workers': coverage_of_this_test,
        }

        assigned_worker_pairs = [
            f'{test_worker_name} -> {real_worker_name}' for real_worker_name, test_worker_name in test_worker_names_by_real_worker_name.items()
        ]
        print(f'{test_file.stem}: assigned {assigned_worker_pairs or "nothing"}')

    overlays_per_test['ALL'] = {'name': 'ALL', 'start_time': None, 'workers': coverage_over_all_tests}

    real_engine['coverage_overlays'] = overlays_per_test
    PATH_OUTPUT.write_text(json.dumps(real_engine, indent=2))
    print(f'written: {PATH_OUTPUT}')


if __name__ == '__main__':
    main()
