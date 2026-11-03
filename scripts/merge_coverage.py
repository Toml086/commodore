import hashlib
import json
import re
from pathlib import Path
from typing import TypedDict, cast

PATH_REAL_ENGINE = Path('notebooks/commodore/build/commodore.json')
DIRECTORY_TEST_RESULTS = Path('notebooks/commodore/build/coverage')
PATH_OUTPUT = Path('notebooks/commodore/build/commodore_coverage.json')
OUTPUT_ENGINE_NAME = 'commodore_coverage'

HANDSHAKE_PATTERN = re.compile(r'WORKER_\d+_(start|idle|select|reset)')


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


class TransitionDefinition(TypedDict):
    target: str
    condition: str | None


class StateDefinition(TypedDict):
    name: str
    unconditional_assignments: list[AssignmentDefinition]
    conditional_assignments: list[object]
    transitions: list[TransitionDefinition]


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


def create_state_key(state_definition: StateDefinition) -> str | None:
    assignments = sorted(f'{assignment["signal"]} = {assignment["value"]}' for assignment in state_definition['unconditional_assignments'])
    conditional_assignments = json.dumps(state_definition['conditional_assignments'], sort_keys=True)
    conditions = [transition['condition'] for transition in state_definition['transitions']]

    has_content = bool(assignments) or state_definition['conditional_assignments'] != [] or any(condition is not None for condition in conditions)
    content_parts: dict[str, object] = {'assignments': assignments, 'conditional_assignments': conditional_assignments, 'conditions': conditions}
    content = json.dumps(content_parts, sort_keys=True)

    if not has_content or HANDSHAKE_PATTERN.search(content):
        return None
    return hashlib.sha256(content.encode()).hexdigest()


def create_uncovered_state_coverage(state_definition: StateDefinition) -> StateCoverage:
    return {'coverage': False, 'transitions': [{'coverage': False} for _ in state_definition['transitions']]}


def create_uncovered_worker_coverage(worker_definition: WorkerDefinition) -> WorkerCoverage:
    return {
        'states': {
            state_name: create_uncovered_state_coverage(state_definition) for state_name, state_definition in worker_definition['states'].items()
        }
    }


def combine_state_coverage(first_coverage: StateCoverage, second_coverage: StateCoverage) -> StateCoverage:
    combined_transitions: list[TransitionCoverage] = []
    for first_transition, second_transition in zip(first_coverage['transitions'], second_coverage['transitions']):
        combined_transitions.append({'coverage': first_transition['coverage'] or second_transition['coverage']})
    return {'coverage': first_coverage['coverage'] or second_coverage['coverage'], 'transitions': combined_transitions}


def combine_worker_coverage(first_coverage: WorkerCoverage, second_coverage: WorkerCoverage) -> WorkerCoverage:
    combined_states: dict[str, StateCoverage] = {}
    for state_name, first_state in first_coverage['states'].items():
        combined_states[state_name] = combine_state_coverage(first_state, second_coverage['states'][state_name])
    return {'states': combined_states}


def create_state_keys(workers: dict[str, WorkerDefinition]) -> dict[tuple[str, str], str | None]:
    state_keys: dict[tuple[str, str], str | None] = {}
    for worker_name, worker_definition in workers.items():
        for state_name, state_definition in worker_definition['states'].items():
            state_keys[(worker_name, state_name)] = create_state_key(state_definition)
    return state_keys


def collect_test_coverage_by_key(
    test_workers: dict[str, WorkerDefinition],
    test_overlay: CoverageOverlay,
) -> dict[str, StateCoverage]:
    coverage_by_key: dict[str, StateCoverage] = {}
    for worker_name, worker_definition in test_workers.items():
        for state_name, state_definition in worker_definition['states'].items():
            state_key = create_state_key(state_definition)
            if state_key is None:
                continue
            state_coverage = test_overlay['workers'][worker_name]['states'][state_name]
            if state_key in coverage_by_key:
                coverage_by_key[state_key] = combine_state_coverage(coverage_by_key[state_key], state_coverage)
            else:
                coverage_by_key[state_key] = state_coverage
    return coverage_by_key


def copy_state_coverage(state_coverage: StateCoverage) -> StateCoverage:
    return {
        'coverage': state_coverage['coverage'],
        'transitions': [{'coverage': transition['coverage']} for transition in state_coverage['transitions']],
    }


def derive_coverage_from_graph(  # noqa: C901
    worker_definition: WorkerDefinition,
    worker_coverage: WorkerCoverage,
    derivable_state_names: set[str],
) -> None:
    state_definitions = worker_definition['states']
    state_coverages = worker_coverage['states']
    start_state_name = next(iter(state_definitions))
    derived_state_names = derivable_state_names | {start_state_name}

    predecessors: dict[str, list[str]] = {state_name: [] for state_name in state_definitions}
    successors: dict[str, list[str]] = {state_name: [] for state_name in state_definitions}
    for state_name, state_definition in state_definitions.items():
        for transition in state_definition['transitions']:
            target_name = transition['target']
            if target_name != state_name:
                successors[state_name].append(target_name)
                predecessors[target_name].append(state_name)

    covered_anchor_names = {
        state_name for state_name in state_definitions if state_name not in derived_state_names and state_coverages[state_name]['coverage']
    }

    reached_state_names: set[str] = {start_state_name}
    states_to_visit: list[str] = [start_state_name]
    for anchor_name in covered_anchor_names:
        for transition_index, transition in enumerate(state_definitions[anchor_name]['transitions']):
            target_name = transition['target']
            transition_is_covered = state_coverages[anchor_name]['transitions'][transition_index]['coverage']
            if transition_is_covered and target_name in derived_state_names and target_name not in reached_state_names:
                reached_state_names.add(target_name)
                states_to_visit.append(target_name)
    while states_to_visit:
        current_name = states_to_visit.pop()
        for target_name in successors[current_name]:
            if target_name in derived_state_names and target_name not in reached_state_names:
                reached_state_names.add(target_name)
                states_to_visit.append(target_name)

    leading_state_names: set[str] = set()
    for state_name in derived_state_names:
        if any(target_name in covered_anchor_names for target_name in successors[state_name]):
            leading_state_names.add(state_name)
            states_to_visit.append(state_name)
    while states_to_visit:
        current_name = states_to_visit.pop()
        for predecessor_name in predecessors[current_name]:
            if predecessor_name in derived_state_names and predecessor_name not in leading_state_names:
                leading_state_names.add(predecessor_name)
                states_to_visit.append(predecessor_name)

    for state_name in derived_state_names:
        has_predecessor = len(predecessors[state_name]) > 0
        has_successor = len(successors[state_name]) > 0
        is_reached = not has_predecessor or state_name in reached_state_names
        is_leading = not has_successor or state_name in leading_state_names
        state_coverages[state_name]['coverage'] = (has_predecessor or has_successor) and is_reached and is_leading

    for state_name in derived_state_names:
        state_coverage = state_coverages[state_name]
        for transition_index, transition in enumerate(state_definitions[state_name]['transitions']):
            target_is_covered = state_coverages[transition['target']]['coverage']
            state_coverage['transitions'][transition_index]['coverage'] = state_coverage['coverage'] and target_is_covered


def create_coverage_of_test(
    real_workers: dict[str, WorkerDefinition],
    real_state_keys: dict[tuple[str, str], str | None],
    test_coverage_by_key: dict[str, StateCoverage],
) -> dict[str, WorkerCoverage]:
    coverage_of_test: dict[str, WorkerCoverage] = {}
    for worker_name, worker_definition in real_workers.items():
        state_coverages: dict[str, StateCoverage] = {}
        derivable_state_names: set[str] = set()

        for state_name, state_definition in worker_definition['states'].items():
            state_key = real_state_keys[(worker_name, state_name)]
            if state_key is None:
                derivable_state_names.add(state_name)

            matching_coverage = test_coverage_by_key.get(state_key) if state_key is not None else None
            if matching_coverage is not None and len(matching_coverage['transitions']) == len(state_definition['transitions']):
                state_coverages[state_name] = copy_state_coverage(matching_coverage)
            else:
                state_coverages[state_name] = create_uncovered_state_coverage(state_definition)

        worker_coverage: WorkerCoverage = {'states': state_coverages}
        derive_coverage_from_graph(worker_definition, worker_coverage, derivable_state_names)
        coverage_of_test[worker_name] = worker_coverage
    return coverage_of_test


def main() -> None:
    real_engine = read_engine_file(PATH_REAL_ENGINE)
    real_workers = real_engine['engine']['workers']
    real_state_keys = create_state_keys(real_workers)
    real_keys = {state_key for state_key in real_state_keys.values() if state_key is not None}

    overlays_per_test: dict[str, CoverageOverlay] = {}
    coverage_over_all_tests: dict[str, WorkerCoverage] = {
        worker_name: create_uncovered_worker_coverage(worker_definition) for worker_name, worker_definition in real_workers.items()
    }

    for test_file in sorted(DIRECTORY_TEST_RESULTS.glob('*.json')):
        test_data = read_engine_file(test_file)
        test_workers = test_data['engine']['workers']

        if not test_data['coverage_overlays']:
            print(f'{test_file.stem}: skipped (no coverage-data included)')
            continue
        test_overlay = next(iter(test_data['coverage_overlays'].values()))

        test_coverage_by_key = collect_test_coverage_by_key(test_workers, test_overlay)
        coverage_of_this_test = create_coverage_of_test(real_workers, real_state_keys, test_coverage_by_key)

        for worker_name, worker_coverage in coverage_of_this_test.items():
            coverage_over_all_tests[worker_name] = combine_worker_coverage(coverage_over_all_tests[worker_name], worker_coverage)

        overlays_per_test[test_file.stem] = {
            'name': test_file.stem,
            'start_time': test_overlay['start_time'],
            'workers': coverage_of_this_test,
        }

        matched_keys = len(real_keys & set(test_coverage_by_key))
        print(f'{test_file.stem}: {matched_keys} of {len(test_coverage_by_key)} non-empty test states exist in the real engine')

    overlays_per_test['ALL'] = {'name': 'ALL', 'start_time': None, 'workers': coverage_over_all_tests}

    real_engine['coverage_overlays'] = overlays_per_test
    real_engine['engine']['name'] = OUTPUT_ENGINE_NAME
    PATH_OUTPUT.write_text(json.dumps(real_engine, indent=2))
    print(f'written: {PATH_OUTPUT}')


if __name__ == '__main__':
    main()
