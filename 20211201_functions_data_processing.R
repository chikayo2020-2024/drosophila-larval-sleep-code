
fillgap = function(myvalue, gap){
  for(k in 2:(length(myvalue)-gap)){
    if((myvalue[k]==1) &
       (myvalue[k-1]==0) & 
       (myvalue[k+gap]==0) &
       (sum(myvalue[k:(k+gap-1)]==1)==gap)){
      #print(paste0('found gap! position : ', k, ', length: ',gap))
      myvalue[k:(k+gap-1)] = 0
    }
  }
  return(myvalue)
}

get_bouts = function(mydata, thresh, gap2fill){
  fly.set = unique(mydata$ID)
  out.bouts = NULL
  for(myfly in fly.set){
    bouts = NULL
    bouts_f = NULL
    subdata = subset(mydata, ID==myfly)
    
    # binarize dPixel (1: awake, 0: asleep)
    myvalue = ifelse(subdata$value>thresh, 1, 0)
    
    # fill X-frame gaps
    if(gap2fill>0){ #{}add
      for(i in 1:gap2fill){ #{}add
        myvalue = fillgap(myvalue, i)
      }
    }
    
    # detect sleep bouts
    if(sum(myvalue==0)==length(myvalue)){ #if all 0
      print(paste0('all frames 0 (asleep) in ',myfly))
      bouts = length(myvalue)
      bouts_f = 0
    } else{
      if(sum(myvalue==1)==length(myvalue)){ #if all 1
        print(paste0('all frames 1 (active) in ',myfly))
        bouts = 0
        bouts_f = 0
      } else{
        # get 0->1 frames
        changepoint.0to1 = 
          lapply(2:length(myvalue), function(mypoint){
            ifelse(myvalue[mypoint]==1 & myvalue[mypoint-1]==0, mypoint, NA)
          }) %>% c()
        changepoint.0to1 = changepoint.0to1 %>% unlist() %>% na.omit() %>% as.numeric()
        
        # get 1->0 frames
        changepoint.1to0 = 
          lapply(2:length(myvalue), function(mypoint){
            ifelse(myvalue[mypoint]==0 & myvalue[mypoint-1]==1, mypoint, NA)
          }) %>% c()
        changepoint.1to0 = changepoint.1to0 %>% unlist() %>% na.omit() %>% as.numeric()
        
        # boundary conditions (initial sleep)  start0000011110000
        if((min(changepoint.0to1)<min(changepoint.1to0)) & (min(changepoint.0to1)>=bout.thresh)){
          bouts = c(bouts, min(changepoint.0to1))
          bouts_f = c(bouts_f, 1)
        }
        
        # define bouts
        for(k in 1:length(changepoint.1to0)){ # bout: sleep bout
          tmp = changepoint.0to1 - changepoint.1to0[k]
          # if all elements < 0 (meaning that all points beyond changepoint.1to0[k] was 0), skip
          if(sum(tmp>0)==0) next
          bouts = c(bouts, min(tmp[tmp>0]))
          bouts_f = c(bouts_f, changepoint.1to0[k])
        }
        
        
        # boundary conditions (last sleep) 000000000011111100000000000end
        if((max(changepoint.1to0)>max(changepoint.0to1)) & (max(changepoint.1to0)<(length(myvalue)-bout.thresh))){
          bouts = c(bouts, length(myvalue) - max(changepoint.1to0))
          bouts_f = c(bouts_f, max(changepoint.1to0))
        }
      }
    }
    out = data.frame(ID=myfly, bout=bouts, bout_startframe = bouts_f)
    out.bouts = rbind(out.bouts, out)
  }
  
  return(out.bouts)
}

processing = function(mydata,thresh,gap2fill){
  elements = NULL
  
  for(k in 1:ncol(mydata)){
    mydata[,k] = mydata[,k] %>% {gsub('\\[','',.)} %>%  {gsub('\\]','',.)} %>% as.numeric
  }
  # colnames(mydata) = c('frame','x','y','radius','value')
  colnames(mydata) = c('frame','value')
  mydata$frame = mydata$frame +2
  mydata$time = mydata$frame / srate
  mydata$ID = 'test'
  
  # mydata = subset(mydata,frame%%15!=0) 
  
  
  # identify bouts
  out.bouts = get_bouts(mydata, thresh,gap2fill)
  out.bouts_threshold = subset(out.bouts, bout>=bout.thresh)
  bout_sleep = out.bouts_threshold$bout
  
  ### bout-length
  sleep_length = mean(bout_sleep)
  
  ### bout-number
  sleep_number = length(bout_sleep)
  
  ### sleep-sum
  sleep_sum = sum(bout_sleep)
  
  elements = c(dir_list[i],l,sleep_length,sleep_number,sleep_sum)
}
