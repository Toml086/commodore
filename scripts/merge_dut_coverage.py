import hashlib
import json
import re
from pathlib import Path
from typing import TypedDict, cast

DIRECTORY_TEST_RESULTS = Path('notebooks/commodore/build/coverage')
PATH_OUTPUT = Path('notebooks/commodore/build/commodore_dut_coverage.json')
OUTPUT_ENGINE_NAME = 'commodore_dut_coverage'
MAIN_WORKER_NAME = 'main'

START_SIGNAL_PATTERN = re.compile(r'WORKER_\d+_start')


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


class AssignmentDefinition(TypedDict):
    signal: str
    value: str


class StateDefinition(TypedDict):
    name: str
    unconditional_assignments: list[AssignmentDefinition]


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


def find_started_worker_names(worker_definition: WorkerDefinition) -> list[str]:
    started_worker_names: list[str] = []
    for state_definition in worker_definition['states'].values():
        for assignment in state_definition['unconditional_assignments']:
            signal_name = assignment['signal']
            if START_SIGNAL_PATTERN.fullmatch(signal_name) is None or assignment['value'] != '1':
                continue
            started_worker_name = signal_name.removesuffix('_start')
            if started_worker_name not in started_worker_names:
                started_worker_names.append(started_worker_name)
    return started_worker_names


def find_dut_worker_name(workers: dict[str, WorkerDefinition]) -> str | None:
    main_worker = workers.get(MAIN_WORKER_NAME)
    if main_worker is None:
        return None
    started_worker_names = find_started_worker_names(main_worker)
    if not started_worker_names:
        return None
    return started_worker_names[0]


def collect_worker_family(workers: dict[str, WorkerDefinition], root_worker_name: str) -> list[str]:
    family_names = [root_worker_name]
    position = 0
    while position < len(family_names):
        for started_worker_name in find_started_worker_names(workers[family_names[position]]):
            if started_worker_name in workers and started_worker_name not in family_names:
                family_names.append(started_worker_name)
        position += 1
    return family_names


def create_family_checksum(workers: dict[str, WorkerDefinition], family_names: list[str]) -> str:
    family_definitions: dict[str, WorkerDefinition] = {worker_name: workers[worker_name] for worker_name in family_names}
    return hashlib.sha256(json.dumps(family_definitions, sort_keys=True).encode()).hexdigest()


def copy_worker_coverage(worker_coverage: WorkerCoverage) -> WorkerCoverage:
    copied_states: dict[str, StateCoverage] = {}
    for state_name, state_coverage in worker_coverage['states'].items():
        copied_transitions: list[TransitionCoverage] = [{'coverage': transition['coverage']} for transition in state_coverage['transitions']]
        copied_states[state_name] = {'coverage': state_coverage['coverage'], 'transitions': copied_transitions}
    return {'states': copied_states}


def combine_worker_coverage(first_coverage: WorkerCoverage, second_coverage: WorkerCoverage) -> WorkerCoverage:
    combined_states: dict[str, StateCoverage] = {}
    for state_name, first_state in first_coverage['states'].items():
        second_state = second_coverage['states'][state_name]
        combined_transitions: list[TransitionCoverage] = []
        for first_transition, second_transition in zip(first_state['transitions'], second_state['transitions']):
            combined_transitions.append({'coverage': first_transition['coverage'] or second_transition['coverage']})
        combined_states[state_name] = {'coverage': first_state['coverage'] or second_state['coverage'], 'transitions': combined_transitions}
    return {'states': combined_states}


def main() -> None:
    reference_file_name: str | None = None
    reference_data: EngineFile | None = None
    reference_family_names: list[str] = []
    reference_checksum = ''

    overlays_per_test: dict[str, CoverageOverlay] = {}
    coverage_over_all_tests: dict[str, WorkerCoverage] = {}
    skipped_test_names: list[str] = []

    for test_file in sorted(DIRECTORY_TEST_RESULTS.glob('*.json')):
        test_data = read_engine_file(test_file)
        test_workers = test_data['engine']['workers']

        if not test_data['coverage_overlays']:
            print(f'{test_file.stem}: skipped (no coverage-data included)')
            continue

        dut_worker_name = find_dut_worker_name(test_workers)
        if dut_worker_name is None or dut_worker_name not in test_workers:
            print(f'{test_file.stem}: skipped (no dut worker found)')
            skipped_test_names.append(test_file.stem)
            continue

        family_names = collect_worker_family(test_workers, dut_worker_name)
        checksum = create_family_checksum(test_workers, family_names)

        if reference_data is None:
            reference_file_name = test_file.stem
            reference_data = test_data
            reference_family_names = family_names
            reference_checksum = checksum

        if checksum != reference_checksum:
            print(f'{test_file.stem}: skipped (checksum {checksum[:12]} differs from {reference_checksum[:12]} of {reference_file_name})')
            skipped_test_names.append(test_file.stem)
            continue

        test_overlay = next(iter(test_data['coverage_overlays'].values()))
        coverage_of_this_test: dict[str, WorkerCoverage] = {
            worker_name: copy_worker_coverage(test_overlay['workers'][worker_name]) for worker_name in family_names
        }

        for worker_name, worker_coverage in coverage_of_this_test.items():
            if worker_name in coverage_over_all_tests:
                coverage_over_all_tests[worker_name] = combine_worker_coverage(coverage_over_all_tests[worker_name], worker_coverage)
            else:
                coverage_over_all_tests[worker_name] = copy_worker_coverage(worker_coverage)

        overlays_per_test[test_file.stem] = {
            'name': test_file.stem,
            'start_time': test_overlay['start_time'],
            'workers': coverage_of_this_test,
        }
        print(f'{test_file.stem}: dut worker {dut_worker_name}, extracted {family_names}, checksum {checksum[:12]}')

    if reference_data is None:
        print('nothing written: no usable test files found')
        return

    overlays_per_test['ALL'] = {'name': 'ALL', 'start_time': None, 'workers': coverage_over_all_tests}

    output_engine: EngineFile = {
        'sha256sum': reference_data['sha256sum'],
        'version': reference_data['version'],
        'engine': {
            'name': OUTPUT_ENGINE_NAME,
            'workers': {worker_name: reference_data['engine']['workers'][worker_name] for worker_name in reference_family_names},
        },
        'coverage_overlays': overlays_per_test,
    }
    PATH_OUTPUT.write_text(json.dumps(output_engine, indent=2))

    used_test_count = len(overlays_per_test) - 1
    print(f'{used_test_count} tests merged, {len(skipped_test_names)} skipped: {skipped_test_names or "none"}')
    print(f'written: {PATH_OUTPUT}')


if __name__ == '__main__':
    main()
