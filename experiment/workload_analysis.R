library(dplyr)
library(ggplot2)
library(readr)

# Load data
alexey_icpe_2017_workload_1 <- read_csv("experiment/input/workload1.gwf",col_types = list(col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_character(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer()))
alexey_icpe_2017_workload_2 <- read_csv("experiment/input/workload2.gwf",col_types = list(col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_character(),
                                                                                          col_integer(),
                                                                                          col_integer(),
                                                                                          col_integer()))

# Determine load of input data and visualise load over time aggregated over time intervals
# Conversion rate runtime to flops opendc is 4000
flops <- 4000

#average load approx 80000 flops
avg_load_1 <- sum(alexey_icpe_2017_workload_1$RunTime)/max(alexey_icpe_2017_workload_1$SubmitTime)*flops
avg_load_2 <- sum(alexey_icpe_2017_workload_2$RunTime)/max(alexey_icpe_2017_workload_2$SubmitTime)*flops

#average load for 15 min time intervals
interval_length <- 60*15
alexey_icpe_2017_workload_1 <- mutate(alexey_icpe_2017_workload_1, interval = floor(SubmitTime/interval_length)*interval_length/60)
alexey_icpe_2017_workload_2 <- mutate(alexey_icpe_2017_workload_2, interval = floor(SubmitTime/interval_length)*interval_length/60)

workload1 <- summarise(group_by(alexey_icpe_2017_workload_1,interval),njobs = length(RunTime),nworkloads = length(unique(WorkflowID)),flops_load = sum(RunTime)*flops/interval_length)
workload2 <- summarise(group_by(alexey_icpe_2017_workload_2,interval),njobs = length(RunTime),nworkloads = length(unique(WorkflowID)),flops_load = sum(RunTime)*flops/interval_length)

#plot load and enviroment capacity
#allow for changes in enviroments / machines
machine1_capacity <- 4*4100
machine2_capacity <- 2*3500

enviroment_1_machine1 <- 5
enviroment_1_machine2 <- 5

enviroment_2_machine1 <- 7
enviroment_2_machine2 <- 0

enviroment_1_capacity <- enviroment_1_machine1*machine1_capacity+enviroment_1_machine2*machine2_capacity
enviroment_2_capacity <- enviroment_2_machine1*machine1_capacity+enviroment_2_machine2*machine2_capacity

#Determine ylim based on the maximum of max observed value and enviroment capacity rounded above in a nice way
highest_interval_arrival_load <- max(workload1$flops_load,workload2$flops_load)

load_plot_ylim <- max(enviroment_1_capacity,enviroment_2_capacity,highest_interval_arrival_load)

load_plot_ylim_size <- nchar(trunc(load_plot_ylim))
load_plot_ylim <- round(load_plot_ylim+0.015*10^load_plot_ylim_size,-(load_plot_ylim_size-2))

# plot
plot_df <- bind_rows(mutate(workload1,identifier = 1), mutate(workload2,identifier = 2))
plot_df$identifier <- as.factor(plot_df$identifier)

plot_load <- ggplot(plot_df, aes(x = interval, y = flops_load)) +
  geom_bar(stat = 'identity',width = interval_length/60) +
  theme_classic() + ylim(0,load_plot_ylim) +
  ggtitle("Average load for 15 min intervals for both workloads") +
  ylab("Arriving workload in flops") +
  xlab("Time in minutes") +
  geom_hline(aes(yintercept = enviroment_1_capacity,linetype = "Enviroment capacity"),size = 1) +
  geom_hline(aes(yintercept = avg_load_1,linetype = "Average load"), size = 1) +
  scale_linetype_manual(name = "", values = c(1, 2),
                        guide = guide_legend(reverse = TRUE)) + facet_wrap(~ identifier, nrow = 1)

ggsave("analysis/Workload load.png",plot = plot_load,width = 30, height = 10, units = "cm")

#####
# arrival process

Arrival_time_1 <- summarise(group_by(alexey_icpe_2017_workload_1,WorkflowID),SubmitTime = min(SubmitTime))
Arrival_time_1 <- mutate(Arrival_time_1, InterArrivalTime = SubmitTime - lag(SubmitTime))
inter_arrival_time <- Arrival_time_1$InterArrivalTime[2:nrow(Arrival_time_1)]

expon_qqplot <- ggplot(Arrival_time_1, aes(sample = InterArrivalTime))+stat_qq(distribution = qexp)+ stat_qq_line(distribution = qexp) + ggtitle("Exponential QQ-plot of inter arrival times")

ggsave("analysis/Exponential qq plot arrival.png",plot = expon_qqplot,width = 10, height = 10, units = "cm")

#####
# some statistics

statistic_description <- c("mean task runtime workload 1","median task runtime workload 1","sd task runtime workload 1","mean job runtime workload 1","median job runtime workload 1","sd job runtime workload 1","total runtime workload 1",
                           "mean task runtime workload 2","median task runtime workload 2","sd task runtime workload 2","mean job runtime workload 2","median job runtime workload 2","sd job runtime workload 1","total runtime workload 2",
                           "mean workflow size","median workflow size","sd workflow size","numtasks",
                           "workflow 1 setup 1 system load","workflow 1 setup 2 system load","workflow 2 setup 1 system load","workflow 2 setup 2 system load")

statistics <- vector(mode = "double", length = 22)

# workload 1 properties
statistics[1] <- mean(alexey_icpe_2017_workload_1$RunTime)
statistics[2] <- median(alexey_icpe_2017_workload_1$RunTime)
statistics[3] <- sd(alexey_icpe_2017_workload_1$RunTime)
WF_properties <- summarise(group_by(alexey_icpe_2017_workload_1,WorkflowID),size = length(WorkflowID),runtime = sum(RunTime))
WF_runtimes <- WF_properties$runtime
statistics[4] <- mean(WF_runtimes)
statistics[5] <- median(WF_runtimes)
statistics[6] <- sd(WF_runtimes)
statistics[7] <- sum(alexey_icpe_2017_workload_1$RunTime)

# workload 2 properties
statistics[8] <- mean(alexey_icpe_2017_workload_2$RunTime)
statistics[9] <- median(alexey_icpe_2017_workload_2$RunTime)
statistics[10] <- sd(alexey_icpe_2017_workload_2$RunTime)
WF_properties <- summarise(group_by(alexey_icpe_2017_workload_2,WorkflowID),size = length(WorkflowID),runtime = sum(RunTime))
WF_runtimes <- WF_properties$runtime
statistics[11] <- mean(WF_runtimes)
statistics[12] <- median(WF_runtimes)
statistics[13] <- sd(WF_runtimes)
statistics[14] <- sum(alexey_icpe_2017_workload_2$RunTime)

# workflow size properties
WF_sizes <- WF_properties$size
statistics[15] <- mean(WF_sizes)
statistics[16] <- median(WF_sizes)
statistics[17] <- sd(WF_sizes)
statistics[14] <- nrow(alexey_icpe_2017_workload_1)

# Average load as fraction of environment capacity
statistics[19] <- avg_load_1/enviroment_1_capacity
statistics[20] <- avg_load_1/enviroment_2_capacity
statistics[21] <- avg_load_2/enviroment_1_capacity
statistics[22] <- avg_load_2/enviroment_2_capacity

# Write all statistics to a csv
write.csv(data.frame(statistic_description,statistics), file = "analysis/workload_statistics.csv", row.names = FALSE, na = "", quote = FALSE)
