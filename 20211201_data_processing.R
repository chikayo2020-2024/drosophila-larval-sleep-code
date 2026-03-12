
source('./R/20211129_init.R')
setwd("C:/.../20211103_mutant-analysis/")
source('./R/20211201_functions_data_processing.R')
library(gridExtra)
library(readr)
library(ggplot2)
library(dplyr)

setwd("C:/.../data")

df = NULL
ID_elements = NULL
thresh=543
gap2fill=0

for (i in 1:length(dir_list)){
  for (l in 0:23){
    elements = NULL
    setwd("C:/.../MJPEG-out_blur-7,thresh-13/")
    
    
    file.name <- sprintf("%s_%d.csv",dir_list[i],l)
    print(file.name)
    if (file.access(file.name) != 0) {  
      print (paste(file.name, ' does not exist.'))  
      next   
    }
    mydata <- read.csv(file.name, header = F)
    
    elements = processing(mydata,thresh,gap2fill) 
    df = rbind(df,elements)
  }
}

df_elements = data.frame(df)
colnames(df_elements) = c("filename","wellID","sleep_length","sleep_number","sleep_sum")

output.file = sprintf("%s_df_3elements.csv",Sys.Date())
setwd("C:/.../20211103_mutant-analysis/Results/")  
write_csv(df_elements, output.file)
