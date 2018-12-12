library(dplyr)
library(readr)
# libraries not used anymore but need to be used to use the commented out code below to determine workflow id's based on dependencies
#library(Matrix)
#library(igraph)

# Load data
alexey_icpe_2017_workload_1 <- read_csv("alexey_icpe_2017_workload_1.gwf")
alexey_icpe_2017_workload_2 <- read_csv("alexey_icpe_2017_workload_2.gwf")

#####
# First workload pre processing
# Job ID's are only unique within each workflow need to be unique overall
# Dependencies need to be updated to new Job ID's

# Create unique job id's for all jobs and determine the smallest value for these unique job id's for each workflow
alexey_icpe_2017_workload_1$NewJobID <- c(0:(nrow(alexey_icpe_2017_workload_1)-1))
alexey_icpe_2017_workload_1 <- mutate(group_by(alexey_icpe_2017_workload_1,WorkflowID),MinJobID = min(NewJobID))
alexey_icpe_2017_workload_1 <- ungroup(alexey_icpe_2017_workload_1)

# Store dependencies in a list, convert to int vectors and for each dependency vector add the smallest unique job id for that workflow
nrows = nrow(alexey_icpe_2017_workload_1)
dependencies_char_vector_list = strsplit(alexey_icpe_2017_workload_1$Dependencies,' ')
dependencies_int_vector_list = sapply(1:nrows, function(x) as.numeric(dependencies_char_vector_list[[x]]))
updated_dependencies_int_vector_list = sapply(1:nrows, function(x) dependencies_int_vector_list[[x]]+alexey_icpe_2017_workload_1$MinJobID[x])

updated_dependencies_char_list = sapply(1:nrows, function(x) paste(updated_dependencies_int_vector_list[[x]],collapse=" "))

alexey_icpe_2017_workload_1$UpdatedDependencies <- updated_dependencies_char_list

# Place updated values in columns JobID and Dependencies and remove all objects that are not relevant anymore
alexey_icpe_2017_workload_1$JobID <- alexey_icpe_2017_workload_1$NewJobID
alexey_icpe_2017_workload_1$Dependencies <- alexey_icpe_2017_workload_1$UpdatedDependencies

alexey_icpe_2017_workload_1 <- select(alexey_icpe_2017_workload_1, WorkflowID, JobID, SubmitTime, RunTime, NProcs, ReqNProcs, Dependencies)
alexey_icpe_2017_workload_1 <- mutate(alexey_icpe_2017_workload_1, Dependencies = ifelse(Dependencies == "NA",NA,Dependencies))
rm(dependencies_char_vector_list, dependencies_int_vector_list, updated_dependencies_int_vector_list, updated_dependencies_char_list)

# generate priorities per workflow and input and output sizes per job
# priority: 3 levels descrete uniform distribution
# input and outputsize: normal distribution with location 1000 and scale 250, negative values set to 0

set.seed(22)
num_workflows = length(unique(alexey_icpe_2017_workload_1$WorkflowID))

num_priorities = 3
priority =  sample(1:num_priorities,num_workflows,replace=T)

inputsize_location = 1000
inputsize_scale = 250

outputsize_location = 1000
outputsize_scale = 250

alexey_icpe_2017_workload_1 <- mutate(alexey_icpe_2017_workload_1, InputSize = as.integer(rnorm(nrows,inputsize_location,inputsize_scale)), OutputSize = as.integer(rnorm(nrows,outputsize_location,outputsize_scale)), Priority = priority[WorkflowID+1])
alexey_icpe_2017_workload_1 <- mutate(alexey_icpe_2017_workload_1, InputSize = ifelse(InputSize < 0, 0,InputSize),OutputSize = ifelse(OutputSize <0,0,OutputSize))

# save as gwf
write.csv(alexey_icpe_2017_workload_1, file = "experiment/input/workload1.gwf", row.names = FALSE, na = "", quote = FALSE)

#####
# Second workload pre processing
# No workflow id's given
#

# arrival and dependencies are identical between workloads, workload 2 has workflow id's missing so assumption is that these are identical between workflows
alexey_icpe_2017_workload_2 <- mutate(alexey_icpe_2017_workload_2,WorkflowID = alexey_icpe_2017_workload_1$WorkflowID)

alexey_icpe_2017_workload_2 <- select(alexey_icpe_2017_workload_2,WorkflowID,JobID,SubmitTime,RunTime,NProcs,ReqNProcs,Dependencies)

# generate input and output sizes same as above
# normal distributed with location 1000 and scale 250
# give same priorites to workflows as they were given to workload 1
inputsize_location = 1000
inputsize_scale = 250

outputsize_location = 1000
outputsize_scale = 250

alexey_icpe_2017_workload_2 <- mutate(alexey_icpe_2017_workload_2, InputSize = as.integer(rnorm(nrows,inputsize_location,inputsize_scale)), OutputSize = as.integer(rnorm(nrows,outputsize_location,outputsize_scale)), Priority = priority[WorkflowID+1])
alexey_icpe_2017_workload_2 <- mutate(alexey_icpe_2017_workload_2, InputSize = ifelse(InputSize < 0, 0,InputSize),OutputSize = ifelse(OutputSize <0,0,OutputSize))

write.csv(alexey_icpe_2017_workload_2, file = "experiment/input/workload2.gwf", row.names = FALSE, na = "", quote = FALSE)


# Initially we determined workload id's using dependencies in code below
# based on code found at: https://stackoverflow.com/questions/47322126/merging-list-with-common-elements
# If you want to run this code uncomment the two libraries at the top (Matrix and igraph)
# the list of vectors Workflows contains 1 vector per workflow and the vector contains the jobID's belonging to that workflow
# We found 341 workflows while workload 1 has 100 workflows
# THis can be explained by the fact that there are workflows in alexey_icpe_2017_workload_1 that are not fully connected
# See workflow 3 and it dependencies and compare it to Workloads[[4]] and Workloads[[5]]
#nrows = nrow(alexey_icpe_2017_workload_2)
#dependencies_char_vector_list = strsplit(alexey_icpe_2017_workload_2$Dependencies,' ')
#dependencies_int_vector_list = sapply(1:nrows, function(x) c(x-1,as.numeric(dependencies_char_vector_list[[x]])))
#
#dependencies_only_int_vector_list = dependencies_int_vector_list[!is.na(dependencies_char_vector_list)]
#
#i = rep(1:length(dependencies_only_int_vector_list), lengths(dependencies_only_int_vector_list))
#j = factor(unlist(dependencies_only_int_vector_list))
#tab = sparseMatrix(i = i, j = as.integer(j), x = TRUE, dimnames = list(NULL, levels(j)))
#
#connects = tcrossprod(tab, boolArith = TRUE)
#
#group = clusters(graph_from_adjacency_matrix(as(connects, "lsCMatrix")))$membership
#
#Workflows = tapply(dependencies_only_int_vector_list, group, function(x) sort(unique(unlist(x))))

# Does the same as the above commented code but verry inefficiently
#temp = unique(sapply(dependencies_only_int_vector_list, function(x)
#  unique(unlist(dependencies_only_int_vector_list[sapply(dependencies_only_int_vector_list, function(y)
#    any(x %in% y))]))))
