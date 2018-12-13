library(readr)
library(ggplot2)
library(dplyr)

tasks1 <- read_csv("data_workload1_setup1/tasks.csv") %>%
  mutate(Category = "Workload 1 setup 1")
task_metrics1 <- read_csv("data_workload1_setup1/task_metrics.csv") %>%
  mutate(Category = "Workload 1 setup 1")
job_metrics1 <- read_csv("data_workload1_setup1/job_metrics.csv") %>%
  mutate(Category = "Workload 1 setup 1")

tasks2 <- read_csv("data_workload1_setup2/tasks.csv") %>%
  mutate(Category = "Workload 1 setup 2")
task_metrics2 <- read_csv("data_workload1_setup2/task_metrics.csv") %>%
  mutate(Category = "Workload 1 setup 2")
job_metrics2 <- read_csv("data_workload1_setup2/job_metrics.csv") %>%
  mutate(Category = "Workload 1 setup 2")

tasks3 <- read_csv("data_workload2_setup1/tasks.csv") %>%
  mutate(Category = "Workload 2 setup 1")
task_metrics3 <- read_csv("data_workload2_setup1/task_metrics.csv") %>%
  mutate(Category = "Workload 2 setup 1")
job_metrics3 <- read_csv("data_workload2_setup1/job_metrics.csv")%>%
  mutate(Category = "Workload 2 setup 1")

tasks4 <- read_csv("data_workload2_setup2/tasks.csv") %>%
  mutate(Category = "Workload 2 setup 2")
task_metrics4 <- read_csv("data_workload2_setup2/task_metrics.csv") %>%
  mutate(Category = "Workload 2 setup 2")
job_metrics4 <- read_csv("data_workload2_setup2/job_metrics.csv") %>%
  mutate(Category = "Workload 2 setup 2")

tasks <- bind_rows(tasks1,
                   tasks2,
                   tasks3,
                   tasks4)

task_metrics <- bind_rows(task_metrics1,
                          task_metrics2,
                          task_metrics3,
                          task_metrics4)

job_metrics <- bind_rows(job_metrics1,
                         job_metrics2,
                         job_metrics3,
                         job_metrics4)

remove(tasks1,
       tasks2,
       tasks3,
       tasks4)

remove(task_metrics1,
       task_metrics2,
       task_metrics3,
       task_metrics4)

remove(job_metrics1,
       job_metrics2,
       job_metrics3,
       job_metrics4)

timeinterval_minutes = 15


df <- task_metrics %>%
  left_join(job_metrics, by = c("job_id" = "job_id", "scheduler" = "scheduler")) %>%
  left_join(distinct(tasks), by = c("task_id" = "id")) %>%
  select(-experiment.x, -experiment.y, -X1.y, -job_id.y) %>%
  mutate(Begin = start_tick + waiting) %>%
  mutate(End = Begin + execution) %>%
  mutate(TimeInterval = ceiling(start_tick / (timeinterval_minutes*60))*timeinterval_minutes) %>%
  select(scheduler, TimeInterval, waiting,Category) %>%
  group_by(scheduler, TimeInterval,Category) %>%
  summarize(Average = mean(waiting))

df1 <-  tasks %>%
  distinct() %>%
  group_by(job_id, Category) %>%
  summarize(MinStart_tick = min(start_tick))

df1 <- job_metrics %>%
  left_join(df1, by = c("job_id" = "job_id")) %>%
  mutate(TimeInterval = ceiling(MinStart_tick / (timeinterval_minutes*60))*timeinterval_minutes) %>%
  group_by(scheduler, TimeInterval, Category.x) %>%
  summarize(Average = mean(waiting_time), Average_Makespan = mean(makespan), Average_critical_path = mean(critical_path))

p1 <- ggplot(df, aes(x = TimeInterval, y = Average, color = scheduler)) +
  geom_line() +
  theme_classic() +
  ggtitle("Graph of the waiting time of tasks averaged for 15 minute intervals") +
  ylab("Average waiting time") +
  xlab("Task arrival time in minutes") +
  facet_wrap(~Category, ncol = 2)

ggsave("analysis/avg_waiting_time_task.png", plot = p1,
        width = 18, height = 8)

p2 <- ggplot(df1, aes(x = TimeInterval, y = Average, color = scheduler)) +
  geom_line() +
  theme_classic() +
  ggtitle("Graph of the wait time of jobs averaged for 15 minute intervals") +
  ylab("Average waiting time") +
  xlab("Job arrival time in minutes")+
  facet_wrap(~Category.x, ncol = 2)

ggsave("analysis/avg_waiting_time_workflow.png", plot = p2,
        width = 18, height = 8)

p3 <- ggplot(task_metrics, aes(x = scheduler, y = waiting)) +
  geom_boxplot(fill='#A4A4A4') +
  theme_classic() +
  ggtitle("Boxplot of waiting time of the task") +
  ylab("Waiting time")+
  facet_wrap(~Category, ncol = 2) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggsave("analysis/waiting_time_task.png", plot = p3,
        width = 18, height = 8)

p4 <- ggplot(job_metrics, aes(x = scheduler, y = waiting_time)) +
  geom_boxplot(fill='#A4A4A4') +
  theme_classic() +
  ggtitle("Boxplot of waiting time of the job") +
  ylab("Waiting time") +
  facet_wrap(~Category, ncol = 2) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggsave("analysis/waiting_time_workflow.png", plot = p4,
        width = 18, height = 8)

p5 <- ggplot(job_metrics, aes(x = scheduler, y = makespan)) +
  geom_boxplot(fill='#A4A4A4') +
  theme_classic() +
  ggtitle("Makespan of the job") +
  ylab("Makespan")+
  facet_wrap(~Category, ncol = 2) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggsave("analysis/makespan_workflow.png", plot = p5,
        width = 18, height = 8)

p6 <- ggplot(df1, aes(x = TimeInterval, y = Average_Makespan, color = scheduler)) +
  geom_line() +
  theme_classic() +
  ggtitle("Graph of the makespan of jobs averaged for 15 minute intervals") +
  ylab("Average waiting time") +
  xlab("Job arrival time in minutes")+
  facet_wrap(~Category.x, ncol = 2)

ggsave("analysis/avg_makespan.png", plot = p6,
       width = 18, height = 8)

p7 <- ggplot(df1, aes(x = TimeInterval, y = Average_critical_path, color = scheduler)) +
  geom_line() +
  theme_classic() +
  ggtitle("Graph of the critical path of jobs averaged for 15 minute intervals") +
  ylab("Average critical path length") +
  xlab("Job arrival time in minutes")+
  facet_wrap(~Category.x, ncol = 2)

ggsave("analysis/avg_critical_path.png", plot = p7,
       width = 18, height = 8)
##t.test
test <- job_metrics %>%
  filter(scheduler %in% c("CPOP", "FIFO-ROUNDROBIN")) %>%
  filter(Category == "Workload 1 setup 1")

a <- unlist((test %>% filter(scheduler == "CPOP") %>% select(makespan))[,1])
b <- unlist((test %>% filter(scheduler == "FIFO-ROUNDROBIN") %>% select(makespan))[,1])
wilcox.test(a, b, paired = TRUE)

test <- job_metrics %>%
  filter(scheduler %in% c("CPOP", "FIFO-ROUNDROBIN")) %>%
  filter(Category == "Workload 1 setup 2")

a <- unlist((test %>% filter(scheduler == "CPOP") %>% select(makespan))[,1])
b <- unlist((test %>% filter(scheduler == "FIFO-ROUNDROBIN") %>% select(makespan))[,1])
wilcox.test(a, b, paired = TRUE)

test <- job_metrics %>%
  filter(scheduler %in% c("CPOP", "FIFO-ROUNDROBIN")) %>%
  filter(Category == "Workload 2 setup 1")

a <- unlist((test %>% filter(scheduler == "CPOP") %>% select(makespan))[,1])
b <- unlist((test %>% filter(scheduler == "FIFO-ROUNDROBIN") %>% select(makespan))[,1])
wilcox.test(a, b, paired = TRUE)

test <- job_metrics %>%
  filter(scheduler %in% c("CPOP", "FIFO-ROUNDROBIN")) %>%
  filter(Category == "Workload 2 setup 2")

a <- unlist((test %>% filter(scheduler == "CPOP") %>% select(makespan))[,1])
b <- unlist((test %>% filter(scheduler == "FIFO-ROUNDROBIN") %>% select(makespan))[,1])
wilcox.test(a, b, paired = TRUE)
