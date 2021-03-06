### 
### Author: Chen Ye
### 
### run_analysis.R


####### Procedure 1: Loading library or forcing you install the package data.table ####### 

###
### Check the current path and guide user to run this script 
### in the root path of the unzipped UCI-HAR-Dataset
###

if ( isTRUE( require(data.table, quietly = TRUE) ) && isTRUE( require(dplyr, quietly = TRUE) )) {
        
        print('Loading data.table package...')
        library("data.table")
        library(dplyr)
        
} else {
        
        print('You must install data.table or dplyr package first...') 
}


####### Procedure 2: Check the current path user is in ####### 

###
### Check the current path and guide user to run this script 
### in the root path of the unzipped UCI-HAR-Dataset
###

if ( length(grep("UCI(.*)HAR(.*)Dataset$", getwd())) ) {

        print('Accessing the UCI HAR Dataset root path now')
  
} else {
        message <- "Your current path is: "
        print('Please make sure you are in the root path of UCI HAR Dataset')
        ## desruptive to your workenvironment ---> quit(save = "no")
        stop(message, getwd())
}


####### Procedure 3: Start loading the raw data to two different variables ####### 

###
### Loading Dataset 
### Two variables: 
###     axtest --- accelerated x test dataset
###     axtrain --- accelerated x train dataset
###
###
### I made a test just for fun, data.table has unbelievable loading speed 
### compared with normal R
###
### > system.time(xtrain <- read.table("train/X_train.txt"))
### user  system elapsed 
### 11.604   0.220  11.845 
### > system.time(axtrain <- fread("train/X_train.txt"))
### user  system elapsed 
### 1.692   0.020   1.712 
###
### > tables()
### NAME     NROW NCOL MB
### [1,] axtest  2,947  561 13
### [2,] axtrain 7,352  561 32
### COLS                                                                             KEY
### [1,] V1,V2,V3,V4,V5,V6,V7,V8,V9,V10,V11,V12,V13,V14,V15,V16,V17,V18,V19,V20,V21,V22,V    
### [2,] V1,V2,V3,V4,V5,V6,V7,V8,V9,V10,V11,V12,V13,V14,V15,V16,V17,V18,V19,V20,V21,V22,V    
### Total: 45MB
###
###

axtest <- fread("test/X_test.txt")
axtrain <- fread("train/X_train.txt")


####### Procedure 4: Merge two dataset rows ####### 

###
### The obtained dataset has been randomly partitioned into two sets, 
### where 70% of the volunteers was selected for generating the training data 
### and 30% the test data. 
###
### Base on above description, merge two dataset with rbind
###
###> tables()
###      NAME             NROW NCOL MB
### ...
### [3,] mergetraintest 10,299  561 45
###
### One variable:
###     mergetraintest --- merge train and test data set (datatable) together
###

mergetraintest <- rbind(axtest, axtrain)


####### Procedure 5: Extracts only mean and std measurement column ####### 

### 
### Load all 561 features to afeatures
###     
### Five variables:
###     afeature --- accelerated features for each column 
###     afeatureindex --- get column number which had mean and str strings
###     firstcolumnlabel --- indirect variable for purpose of add a new column for activity_labels
###     columnlabel --- create labels for the data table
###     mergetraintestr1 --- leave only columns have mean or std strings as column label
###

afeatures <- fread("features.txt")
afeatureindex <- as.data.frame(afeatures[like(V2, "mean") | like(V2, "std")][,1])[,1]
afeaturelabel <- afeatures[like(V2, "mean") | like(V2, "std")][,2]
firstcolumnlabel <- data.table(V2=c("activity_labels"))
columnlabel <- rbind(firstcolumnlabel, afeaturelabel)

## grep unable to work with data.table
## afeatureindex <- grep("mean|std", afeatures[, 2])
## afeaturelabel <- grep("mean|std", afeatures[, 2], value=TRUE)
## mergetraintestr1 <- mergetraintest[ , ..afeatureindex]
## 

mergetraintestr1 <- mergetraintest[ , ..afeatureindex]


####### Procedure 6: Add suject and activity as first and second column ####### 

### Name the activity using descriptive name
### Add 1st and second column to the data table 
### 
###
###     number --- as a vector size matched with label which are six
###     label --- activity strings and remove the underline
###     testname --- mirrored data table of aytest
###     trainame --- mirrored data table of aytrain
###     mergelabels --- merge test and train labels to one data table
###     mergetraintestr2 --- merge data table mergelabels as the 'first' column with original data table 
###     newname --- new column name
###     oldname --- old column name
###     setnames() replace old name "addfirst V1 V2 ..." to "activity_labels tBodyAcc-mean()-X ..."
###

aytest <- fread("test/y_test.txt")
aytrain <- fread("train/y_train.txt")
        
number <- as.character(1:6)
label <- c("WALKING","WALKING_UPSTAIRS","WALKING_DOWNSTAIRS","SITTING","STANDING","LAYING")
label <- gsub("_","", label)

testname <- aytest
for(i in seq_along(number)){
        testname[ , V1 := as.character(V1)][V1 == i, V1 := label[i]]
}

trainame <- aytrain
for(i in seq_along(number)){
        trainame[ , V1 := as.character(V1)][V1 == i, V1 := label[i]]
}

# Deprecated way for data.table
# trainame <- aytrain
# for(i in number){
#         trainame <- gsub(number[i],label[i], trainame)
# }

### if bind column with original numeric value
#aytest <- fread("test/y_test.txt")
#aytrain <- fread("train/y_train.txt")

### bind test and traing string labels and bind to the original data table as the 2st col.
mergelabels <- rbind(aytest, aytrain)
setnames(mergelabels, "V1", "addfirst")

## Character vector start with "activity_labels"
newname <- as.data.frame(columnlabel)[,1]

## data table mergelabels 1st column name is "addfirst", mergetraintestr1 is "V1" 
mergetraintestr2 <- cbind(mergelabels, mergetraintestr1)

oldname <- names(mergetraintestr2)

for (j in seq_along(oldname)) {
        
        setnames(mergetraintestr2,oldname[j], newname[j])
}

### bind test and traing suject string labels and bind to the original data table as the 1st col.

sujectest <- fread("test/subject_test.txt")
sujectrain <- fread("train/subject_train.txt")

sujectraintest <- rbind(sujectest, sujectrain)
setnames(sujectraintest, "V1", "subject")

# Final merge with first column as "suject" column
mergetraintestr3 <- cbind(sujectraintest, mergetraintestr2)

###
### > for (j in seq_along(oldname)) {
# +     
#         +     setnames(mergetraintestr2,oldname[j], newname[j])
# + }
# Error in setnames(mergetraintestr2, oldname[j], newname[j]) : 
#         Some items of 'old' are duplicated (ambiguous) in column names: V1
# > names(mergetraintestr2)
# [1] "V1"   "V1"   "V2"   "V3"   "V4"   "V5"   "V6"   "V41"  "V42"  "V43"  "V44"  "V45"  "V46"  "V81"  "V82"  "V83"  "V84" 
# [18] "V85"  "V86"  "V121" "V122" "V123" "V124" "V125" "V126" "V161" "V162" "V163" "V164" "V165" "V166" "V201" "V202" "V214"
# [35] "V215" "V227" "V228" "V240" "V241" "V253" "V254" "V266" "V267" "V268" "V269" "V270" "V271" "V294" "V295" "V296" "V345"
# [52] "V346" "V347" "V348" "V349" "V350" "V373" "V374" "V375" "V424" "V425" "V426" "V427" "V428" "V429" "V452" "V453" "V454"
# [69] "V503" "V504" "V513" "V516" "V517" "V526" "V529" "V530" "V539" "V542" "V543" "V552"
##
##
##> mergetraintestr3[1, ]
##   subject activity_labels tBodyAcc-mean()-X tBodyAcc-mean()-Y tBodyAcc-mean()-Z tBodyAcc-std()-X tBodyAcc-std()-Y tBodyAcc-std()-Z
##1:       2        STANDING         0.2571778       -0.02328523       -0.01465376        -0.938404       -0.9200908       -0.6676833
##   tGravityAcc-mean()-X tGravityAcc-mean()-Y tGravityAcc-mean()-Z tGravityAcc-std()-X tGravityAcc-std()-Y tGravityAcc-std()-Z
##1:            0.9364893           -0.2827192            0.1152882          -0.9254273          -0.9370141          -0.5642884
##   tBodyAccJerk-mean()-X tBodyAccJerk-mean()-Y tBodyAccJerk-mean()-Z tBodyAccJerk-std()-X tBodyAccJerk-std()-Y tBodyAccJerk-std()-Z
##1:            0.07204601             0.0457544            -0.1060427           -0.9066828           -0.9380164           -0.9359358
##   tBodyGyro-mean()-X tBodyGyro-mean()-Y tBodyGyro-mean()-Z tBodyGyro-std()-X tBodyGyro-std()-Y tBodyGyro-std()-Z tBodyGyroJerk-mean()-X
##1:          0.1199762        -0.09179234          0.1896285        -0.8830891        -0.8161636        -0.9408812             -0.2048962
##   tBodyGyroJerk-mean()-Y tBodyGyroJerk-mean()-Z tBodyGyroJerk-std()-X tBodyGyroJerk-std()-Y tBodyGyroJerk-std()-Z tBodyAccMag-mean()
##1:             -0.1744877            -0.09338934            -0.9012242            -0.9108601            -0.9392504         -0.8669294
##   tBodyAccMag-std() tGravityAccMag-mean() tGravityAccMag-std() tBodyAccJerkMag-mean() tBodyAccJerkMag-std() tBodyGyroMag-mean()
##1:        -0.7051911            -0.8669294           -0.7051911             -0.9297665            -0.8959942          -0.7955439
##   tBodyGyroMag-std() tBodyGyroJerkMag-mean() tBodyGyroJerkMag-std() fBodyAcc-mean()-X fBodyAcc-mean()-Y fBodyAcc-mean()-Z fBodyAcc-std()-X
##1:         -0.7620732              -0.9251949             -0.8943436        -0.9185097        -0.9182132        -0.7890915       -0.9482903
##   fBodyAcc-std()-Y fBodyAcc-std()-Z fBodyAcc-meanFreq()-X fBodyAcc-meanFreq()-Y fBodyAcc-meanFreq()-Z fBodyAccJerk-mean()-X fBodyAccJerk-mean()-Y
##1:       -0.9251369       -0.6363167            0.01111695             0.1212507            -0.5229487            -0.8996332             -0.937485
##   fBodyAccJerk-mean()-Z fBodyAccJerk-std()-X fBodyAccJerk-std()-Y fBodyAccJerk-std()-Z fBodyAccJerk-meanFreq()-X fBodyAccJerk-meanFreq()-Y
##1:            -0.9235514           -0.9244291           -0.9432104           -0.9478915                 0.4510054                  0.137167
##   fBodyAccJerk-meanFreq()-Z fBodyGyro-mean()-X fBodyGyro-mean()-Y fBodyGyro-mean()-Z fBodyGyro-std()-X fBodyGyro-std()-Y fBodyGyro-std()-Z
##1:                -0.1802991         -0.8235579          -0.807916         -0.9179126        -0.9032627         -0.822677        -0.9561651
##   fBodyGyro-meanFreq()-X fBodyGyro-meanFreq()-Y fBodyGyro-meanFreq()-Z fBodyAccMag-mean() fBodyAccMag-std() fBodyAccMag-meanFreq()
##1:              0.1840346            -0.05932286              0.4381072         -0.7909464         -0.711074             -0.4834525
##   fBodyBodyAccJerkMag-mean() fBodyBodyAccJerkMag-std() fBodyBodyAccJerkMag-meanFreq() fBodyBodyGyroMag-mean() fBodyBodyGyroMag-std()
##1:                 -0.8950612                -0.8963596                    -0.03535579                -0.77061             -0.7971128
##   fBodyBodyGyroMag-meanFreq() fBodyBodyGyroJerkMag-mean() fBodyBodyGyroJerkMag-std() fBodyBodyGyroJerkMag-meanFreq()
##1:                  -0.0473913                  -0.8901655                 -0.9073076                      0.07164545
##
##
##
## 


####### Procedure 7: Group by subject and activity_lables, and calculate mean for each column ####### 

###
###

df1 <- as.data.frame(mergetraintestr3)
completeout <- df1 %>% group_by(subject, activity_labels) %>% summarize_all(mean)


##> str(df1)
##'data.frame':	10299 obs. of  81 variables:
## $ subject                        : int  2 2 2 2 2 2 2 2 2 2 ...
## $ activity_labels                : chr  "STANDING" "STANDING" "STANDING" "STANDING" ...
## $ tBodyAcc-mean()-X              : num  0.257 0.286 0.275 0.27 0.275 ...
## $ tBodyAcc-mean()-Y              : num  -0.0233 -0.0132 -0.0261 -0.0326 -0.0278 ...
## $ tBodyAcc-mean()-Z              : num  -0.0147 -0.1191 -0.1182 -0.1175 -0.1295 ...
## $ tBodyAcc-std()-X               : num  -0.938 -0.975 -0.994 -0.995 -0.994 ...
## $ tBodyAcc-std()-Y               : num  -0.92 -0.967 -0.97 -0.973 -0.967 ...
## $ tBodyAcc-std()-Z               : num  -0.668 -0.945 -0.963 -0.967 -0.978 ...
## $ tGravityAcc-mean()-X           : num  0.936 0.927 0.93 0.929 0.927 ...
## $ tGravityAcc-mean()-Y           : num  -0.283 -0.289 -0.288 -0.293 -0.303 ...
## $ tGravityAcc-mean()-Z           : num  0.115 0.153 0.146 0.143 0.138 ...
## $ tGravityAcc-std()-X            : num  -0.925 -0.989 -0.996 -0.993 -0.996 ...
## $ tGravityAcc-std()-Y            : num  -0.937 -0.984 -0.988 -0.97 -0.971 ...
## $ tGravityAcc-std()-Z            : num  -0.564 -0.965 -0.982 -0.992 -0.968 ...
## $ tBodyAccJerk-mean()-X          : num  0.072 0.0702 0.0694 0.0749 0.0784 ...
## $ tBodyAccJerk-mean()-Y          : num  0.04575 -0.01788 -0.00491 0.03227 0.02228 ...
## $ tBodyAccJerk-mean()-Z          : num  -0.10604 -0.00172 -0.01367 0.01214 0.00275 ...
## $ tBodyAccJerk-std()-X           : num  -0.907 -0.949 -0.991 -0.991 -0.992 ...
## $ tBodyAccJerk-std()-Y           : num  -0.938 -0.973 -0.971 -0.973 -0.979 ...
## $ tBodyAccJerk-std()-Z           : num  -0.936 -0.978 -0.973 -0.976 -0.987 ...
## $ tBodyGyro-mean()-X             : num  0.11998 -0.00155 -0.04821 -0.05664 -0.05999 ...
## $ tBodyGyro-mean()-Y             : num  -0.0918 -0.1873 -0.1663 -0.126 -0.0847 ...
## $ tBodyGyro-mean()-Z             : num  0.1896 0.1807 0.1542 0.1183 0.0787 ...
## $ tBodyGyro-std()-X              : num  -0.883 -0.926 -0.973 -0.968 -0.975 ...
## $ tBodyGyro-std()-Y              : num  -0.816 -0.93 -0.979 -0.975 -0.978 ...
## $ tBodyGyro-std()-Z              : num  -0.941 -0.968 -0.976 -0.963 -0.968 ...
## $ tBodyGyroJerk-mean()-X         : num  -0.2049 -0.1387 -0.0978 -0.1022 -0.0918 ...
## $ tBodyGyroJerk-mean()-Y         : num  -0.1745 -0.0258 -0.0342 -0.0447 -0.029 ...
## $ tBodyGyroJerk-mean()-Z         : num  -0.0934 -0.0714 -0.06 -0.0534 -0.0612 ...
## $ tBodyGyroJerk-std()-X          : num  -0.901 -0.962 -0.984 -0.984 -0.988 ...
## $ tBodyGyroJerk-std()-Y          : num  -0.911 -0.956 -0.988 -0.99 -0.992 ...
## $ tBodyGyroJerk-std()-Z          : num  -0.939 -0.981 -0.976 -0.981 -0.982 ...
## $ tBodyAccMag-mean()             : num  -0.867 -0.969 -0.976 -0.974 -0.976 ...
## $ tBodyAccMag-std()              : num  -0.705 -0.954 -0.979 -0.977 -0.977 ...
## $ tGravityAccMag-mean()          : num  -0.867 -0.969 -0.976 -0.974 -0.976 ...
## $ tGravityAccMag-std()           : num  -0.705 -0.954 -0.979 -0.977 -0.977 ...
## $ tBodyAccJerkMag-mean()         : num  -0.93 -0.974 -0.982 -0.983 -0.987 ...
## $ tBodyAccJerkMag-std()          : num  -0.896 -0.941 -0.971 -0.975 -0.989 ...
## $ tBodyGyroMag-mean()            : num  -0.796 -0.898 -0.939 -0.947 -0.957 ...
## $ tBodyGyroMag-std()             : num  -0.762 -0.911 -0.972 -0.97 -0.969 ...
## $ tBodyGyroJerkMag-mean()        : num  -0.925 -0.973 -0.987 -0.989 -0.99 ...
## $ tBodyGyroJerkMag-std()         : num  -0.894 -0.944 -0.984 -0.986 -0.99 ...
## $ fBodyAcc-mean()-X              : num  -0.919 -0.961 -0.992 -0.993 -0.992 ...
## $ fBodyAcc-mean()-Y              : num  -0.918 -0.964 -0.965 -0.968 -0.969 ...
## $ fBodyAcc-mean()-Z              : num  -0.789 -0.957 -0.967 -0.967 -0.98 ...
## $ fBodyAcc-std()-X               : num  -0.948 -0.984 -0.995 -0.996 -0.995 ...
## $ fBodyAcc-std()-Y               : num  -0.925 -0.97 -0.974 -0.977 -0.967 ...
## $ fBodyAcc-std()-Z               : num  -0.636 -0.942 -0.962 -0.969 -0.978 ...
## $ fBodyAcc-meanFreq()-X          : num  0.0111 0.3521 0.1804 0.0627 -0.0189 ...
## $ fBodyAcc-meanFreq()-Y          : num  0.12125 0.17455 0.13346 0.26172 -0.00998 ...
## $ fBodyAcc-meanFreq()-Z          : num  -0.5229 -0.3207 0.1827 0.1518 0.0952 ...
## $ fBodyAccJerk-mean()-X          : num  -0.9 -0.944 -0.991 -0.991 -0.991 ...
## $ fBodyAccJerk-mean()-Y          : num  -0.937 -0.969 -0.973 -0.972 -0.98 ...
## $ fBodyAccJerk-mean()-Z          : num  -0.924 -0.973 -0.972 -0.97 -0.983 ...
## $ fBodyAccJerk-std()-X           : num  -0.924 -0.962 -0.992 -0.992 -0.994 ...
## $ fBodyAccJerk-std()-Y           : num  -0.943 -0.98 -0.971 -0.975 -0.979 ...
## $ fBodyAccJerk-std()-Z           : num  -0.948 -0.981 -0.972 -0.981 -0.989 ...
## $ fBodyAccJerk-meanFreq()-X      : num  0.451 0.473 0.271 0.277 0.18 ...
## $ fBodyAccJerk-meanFreq()-Y      : num  0.1372 0.1672 -0.2722 -0.0383 -0.1392 ...
## $ fBodyAccJerk-meanFreq()-Z      : num  -0.1803 -0.2431 -0.0825 0.0218 0.1009 ...
## $ fBodyGyro-mean()-X             : num  -0.824 -0.923 -0.973 -0.972 -0.976 ...
## $ fBodyGyro-mean()-Y             : num  -0.808 -0.926 -0.981 -0.981 -0.98 ...
## $ fBodyGyro-mean()-Z             : num  -0.918 -0.968 -0.972 -0.967 -0.969 ...
## $ fBodyGyro-std()-X              : num  -0.903 -0.927 -0.973 -0.967 -0.974 ...
## $ fBodyGyro-std()-Y              : num  -0.823 -0.932 -0.977 -0.972 -0.977 ...
## $ fBodyGyro-std()-Z              : num  -0.956 -0.97 -0.979 -0.965 -0.97 ...
## $ fBodyGyro-meanFreq()-X         : num  0.184 0.0181 -0.4791 -0.497 -0.4275 ...
## $ fBodyGyro-meanFreq()-Y         : num  -0.0593 -0.2273 -0.2101 -0.4999 -0.2781 ...
## $ fBodyGyro-meanFreq()-Z         : num  0.4381 -0.1517 0.0493 -0.2589 -0.2913 ...
## $ fBodyAccMag-mean()             : num  -0.791 -0.954 -0.976 -0.973 -0.978 ...
## $ fBodyAccMag-std()              : num  -0.711 -0.96 -0.984 -0.982 -0.979 ...
## $ fBodyAccMag-meanFreq()         : num  -0.4835 0.2035 0.3425 0.3312 0.0711 ...
## $ fBodyBodyAccJerkMag-mean()     : num  -0.895 -0.945 -0.971 -0.972 -0.987 ...
## $ fBodyBodyAccJerkMag-std()      : num  -0.896 -0.934 -0.97 -0.978 -0.99 ...
## $ fBodyBodyAccJerkMag-meanFreq() : num  -0.0354 -0.4912 0.1407 0.1486 0.4222 ...
## $ fBodyBodyGyroMag-mean()        : num  -0.771 -0.924 -0.975 -0.976 -0.977 ...
## $ fBodyBodyGyroMag-std()         : num  -0.797 -0.917 -0.974 -0.971 -0.97 ...
## $ fBodyBodyGyroMag-meanFreq()    : num  -0.0474 -0.0315 -0.1688 -0.2856 -0.3491 ...
## $ fBodyBodyGyroJerkMag-mean()    : num  -0.89 -0.952 -0.986 -0.986 -0.99 ...
## $ fBodyBodyGyroJerkMag-std()     : num  -0.907 -0.938 -0.983 -0.986 -0.991 ...
## $ fBodyBodyGyroJerkMag-meanFreq(): num  0.0716 -0.4012 0.0629 0.1167 -0.1217 ...
##
## 
##> df1 %>% group_by(subject, activity_labels) %>% summarize_all(mean)
### A tibble: 180 x 81
### Groups:   subject [?]
##   subject   activity_labels `tBodyAcc-mean()-X` `tBodyAcc-mean()-Y` `tBodyAcc-mean()-Z` `tBodyAcc-std()-X` `tBodyAcc-std()-Y`
##     <int>             <chr>               <dbl>               <dbl>               <dbl>              <dbl>              <dbl>
## 1       1            LAYING           0.2215982        -0.040513953          -0.1132036        -0.92805647       -0.836827406
## 2       1           SITTING           0.2612376        -0.001308288          -0.1045442        -0.97722901       -0.922618642
## 3       1          STANDING           0.2789176        -0.016137590          -0.1106018        -0.99575990       -0.973190056
## 4       1           WALKING           0.2773308        -0.017383819          -0.1111481        -0.28374026        0.114461337
## 5       1 WALKINGDOWNSTAIRS           0.2891883        -0.009918505          -0.1075662         0.03003534       -0.031935943
## 6       1   WALKINGUPSTAIRS           0.2554617        -0.023953149          -0.0973020        -0.35470803       -0.002320265
## 7       2            LAYING           0.2813734        -0.018158740          -0.1072456        -0.97405946       -0.980277399
## 8       2           SITTING           0.2770874        -0.015687994          -0.1092183        -0.98682228       -0.950704499
## 9       2          STANDING           0.2779115        -0.018420827          -0.1059085        -0.98727189       -0.957304989
##10       2           WALKING           0.2764266        -0.018594920          -0.1055004        -0.42364284       -0.078091253
