library(mice)
library(missForest)
library(dplyr)

library(MASS)
library(Amelia)
library(missMDA)
library(softImpute)
library(tidyr)
library(ggplot2)
library(devtools)
library(gdata)
library(mltools)
library(parallel)

source('/Users/siysun/Desktop/PhD/My_Project/DL-vs-Stat_Impute/Rcode/amputation.R')

#Please modify the path o current code_path in your system 

mainPath <- "/Users/siysun/Desktop/PhD/My_Project/DL-vs-Stat_Impute"

#find the file that contain miss and full datasets
dataMainPath <- file.path(mainPath, "data_stored")
originalPath <- file.path(dataMainPath, "data")
missingMechanism <- list("MCAR", "MAR", "MNAR")
# caseList <- c(1:10)# the case index list, new index could be added in by expanding the range.
caseList <- c(14)

missList <- as.numeric(list(10, 30, 50)) # The defined missing ratios

species <- list("data_miss", "data_miss_sampletest")
#100 for training times and 10 is for sample test times
species_sampletime <- as.numeric(list(10, 2))

for(s in 1:length(species)){
  missPath <- file.path(dataMainPath, species[s])
  sampleTime = species_sampletime[s]
  # dir.create(missPath)
  for(method_index in 1:length(missingMechanism)){
    method <- missingMechanism[method_index]
    methodPath <- file.path(missPath, method)
    # dir.create(methodPath)
    #k is the case index for loop
    for(k in 1:length(caseList)){
      #find the path of full file
      file_name <- paste(toString(caseList[k]), ".csv", sep = "")
      ful_add <- file.path(originalPath, file_name)
      full_df <- read.csv(ful_add)
      
      if(caseList[k] == 6){
        cat <- c(10)
        full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
      }
      else if(caseList[k] == 11){
        cat <- c(1) # first feature Sex is categorical feature
        full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
      }
      else if(caseList[k] == 12){
        cat <- c(2,4,6,7,8,9,10,14,15) # index of categorical feature
        full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
      }
      else if(caseList[k] == 13){
        cat <- c(2,3,8,9,11) # index of categorical feature
        full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
      }
      else if(caseList[k] == 14){
        cat <- c(1,6,7,8) # index of categorical feature
        full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
      }
      # else if(caseList[k] == 7){
      #   cat <- c(4)
      #   full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
      # }
      #If new dataset was added in, after assigned the new data with a new integer name as case index.
        #you could add code below in "else if" block for querying;
        #else if(k == Index_new){
          #cat <- c({The index for the categorical features counted from initial 1})
          #full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
        #}
        #
      # else if(caseList[k] > 7){
      #   cat <- c(11, 12, 13, 14, 15)
      #   full_df[cat] <- lapply(full_df[cat], function(x) as.factor(x))
      # }

      case_name <- paste("Case", toString(caseList[k]), sep = "")
      case_add <- file.path(methodPath, case_name)
      dir.create(case_add)
      for(j in 1:length(missList)){
        miss_rate <- missList[j]
        miss_name <- paste("miss", toString(miss_rate), sep = "")
        mis_add <- file.path(case_add, miss_name)
        dir.create(mis_add)
        mclapply(1:sampleTime, function(i) {
          file_name <- paste(toString(i-1), ".csv", sep = "")
          file_path <- file.path(mis_add, file_name)
          miss_df <- produce_NA(full_df, mechanism = method, perc.missing = miss_rate/100)
          Miss_df <- as.data.frame(miss_df$data.incomp)
          write.csv(Miss_df, file_path, row.names = FALSE)
        }, mc.cores = sampleTime)
      }
    }
  }
}