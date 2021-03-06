# Distributed System Lab Exercise

This was done as a Lab exercise for Distributed Computing Systems at the VU
Amsterdam.

The report can be found in the report directory, both in pdf and latex source.

The source code can be found in the [expirements] branch, which is a fork of
[OpenDC].

For repeatability a single script is written to run the entire experiment. To
run the script the following software is required:

 - Bash, needed to run the script.
 - Kotlin compiler (including Java requirements), needed to compile OpenDC.
 - R (Rscript command), needed to create graphs.

Workloads and setups are also required to be present in the `expirements/input`
directory. For our paper 2 setups are used (present in the directory) and 2
workloads based on the workload used in the paper by Ilyushkin, Alexey, et al.
"An experimental performance evaluation of autoscaling policies for complex
workflows" [1], these workloads are not present in the directory. The workloads
from the paper must first be transformed (using the
`experiment/transform_workload.R` script) before they can be used.

To run the experiment checkout the [expirements] branch, and in the root of the
repo run `$ ./experiment/run.bash`.

After the script is run a number of directories are created:

 - analysis, here a number of graphs are stored used in the paper.
 - data_workload$n_setup$n, output data generated by OpenDC for "workload$n" and
   setup "setup$n", see "experiment/input" for the workloads and setups.

[1]: Ilyushkin, Alexey, et al. "An experimental performance evaluation of
autoscaling policies for complex workflows." Proceedings of the 8th ACM/SPEC on
International Conference on Performance Engineering. ACM, 2017.

[expirements]: https://github.com/Thomasdezeeuw/distributed-systems-lab/tree/experiment
[OpenDC]: https://github.com/atlarge-research/opendc-simulator
