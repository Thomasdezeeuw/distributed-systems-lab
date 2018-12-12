#! /bin/bash

# Run at the root of the opendc-simulator repo.

set -eu

# Make sure we don't overwrite any data.
ls data* 1> /dev/null 2>&1 && echo "Possible data ('data*' directories) exists, please remove first." && exit 1
[ -d analysis ] && echo "'analysis' directory exists, not overwriting" && exit 1

# Make sure we run the latests version.
./gradlew installDist

# Generate all workloads
for workload in experiment/input/*.gwf; do
	workload_name=$(basename "$workload")
	workload_name=${workload_name%.gwf}

	for setup in experiment/input/setup*.json; do
		setup_name=$(basename "$setup")
		setup_name=${setup_name%.json}

		echo "Running workload '$workload' with setup file '$setup'"

		./opendc-model-odc/sc18/build/install/sc18/bin/sc18 --setup "$setup" \
			--schedulers "SRTF-ROUNDROBIN" \
			--schedulers "FIFO-ROUNDROBIN" \
			--schedulers "RANDOM-ROUNDROBIN" \
			--schedulers "PISA-ROUNDROBIN" \
			--schedulers "PISA-BESTFIT" \
			--schedulers "PISA-FIRSTFIT" \
			--schedulers "PISA-WORSTFIT" \
			--schedulers "HEFT" \
			--schedulers "CPOP" \
			"$workload"

		mv "data" "data_${workload_name}_${setup_name}"
	done
done
