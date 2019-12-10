## Feature Engineering Script ##

# 1. 경로 설정
setwd("C:/r")
path.dir <- "./daconData/결과데이터셋/"
source(file = './05.dacon14_common.R')

# 2. 라이브러리 호출
require(caret);require(dplyr);require(mlbench);require(e1071);require(data.table)
require(klaR);require(pls);require(ipred);require(randomForest);require(sampling);require(glmnet)
require(xgboost)

set.seed(100)
Imp.var <-   c( "in_out", "latitude", "longitude", "X6.7_ride",  "X7.8_ride", 
                 "X8.9_ride" ,    "X9.10_ride",  "X10.11_ride",  "X11.12_ride",   "X6.7_takeoff", "X7.8_takeoff",  
                "X8.9_takeoff", "X9.10_takeoff" ,  "X10.11_takeoff" , "X11.12_takeoff" , "X18.20_ride" ,   "weekdays",  "holidays",      
                "city_name",     "town_name",   "hospital",    "bank" ,        "school" ,     "academy" ,   "culture",
                "food", "cafe")


exclude.var <- c('id', 'date', 'bus_route_id', 'station_code', 'station_name', "train_test", "address_no"
                 ,'rainfall', 'weekdays', 'city_name', 'town_name')

Yvar    <- c('X18.20_ride')

# 3. 데이터 호출
# 3.1 full.data : 원핫인코딩 안된 DataFrame 호출
# full.data <- fread(paste0(path.dir, 'full_data.csv'), encoding = 'UTF-8')
load(paste0(path.dir, 'full_data.RData'))
full.data <- full.data %>% filter(train_test == 'train')
full.data[,'city_name'] <- as.factor(full.data[,'city_name'])
full.data[,'town_name'] <- as.factor(full.data[,'town_name'])
full.data[,'weekdays']  <- as.factor(full.data[,'weekdays'])
full.data[,'holidays']  <- as.factor(full.data[,'holidays'])


# 3.2 full.data_oneHotEncoding : 원핫인코딩된 DataFrame 호출
# full.data.encoding <- fread(paste0(path.dir, 'full.data_oneHotEncoding.csv'), encoding = 'UTF-8')
load(paste0(path.dir, 'full_data_oneHotEncoding.RData'))
full.data.encoding <- full.data_oneHotEncoding
full.data.encoding <- full.data.encoding %>% filter(train_test == 'train')

# View(head(full.data))
# View(head(full.data.encoding))

# 4. 층화 샘플링 진행. 날짜별 30% 씩 sampling

full.data.sample         <- srswor_sampling(
  df     = full.data
  , nrate  = 1.0
  , strVar = 'date'
  , Var    = c(Yvar, Imp.var)
)


Imp.var.encoding <- colnames(full.data.encoding)[!colnames(full.data.encoding) %in% exclude.var]

full.data.encoding.sample <- srswor_sampling(
    df     = full.data.encoding
  , nrate  = 0.05
  , strVar = 'date'             
  , Var    = c(Yvar, Imp.var.encoding)
)


# 5.  영향 인자로 탐지하고자 하는 컬럼만 선택
# 5.1 full.data
fml  <- formula(paste0(Yvar, " ~ ", paste(paste(Imp.var, collapse =' + '), ' + latitude:longitude'))) 

# 5.2 full.data.encoding
fmle <- formula(paste0(Yvar, " ~ ", paste(paste(Imp.var.encoding, collapse =' + '), '+ latitude:longitude')))


# 4. 영향 인자 탐지

# 4.1 데이터 구성
# train : 70%, test : 30%
indexTrain <- createDataPartition(1:nrow(full.data.sample), p = .7, list = F)
training   <- data.frame(full.data.sample[ indexTrain, ])
testing    <- data.frame(full.data.sample[-indexTrain, ])

training_encoding   <- data.frame(full.data.encoding.sample[ indexTrain, ])
testing_encoding    <- data.frame(full.data.encoding.sample[-indexTrain, ])



# 4.2 cross-validation 10-fold , 반복 5번 ==> 총 50번 
cv_k   = 2
cv_rep = 1  

fitControl <- trainControl(method    = "cv"
                           , number  = cv_k
                           # , repeats = cv_rep
                           )


# foreach 구문을 통한 병렬 처리 구성
# 병렬처리 적용시, %do% -> %dopar% 로 변경
# one-hot encoding 이 필요한 모델을 제외한 모델 생성 및 영향인자탐지
objectName <- foreach(algo = sAlgo, .combine = cbind) %do% {
  
  # code 
  switch(algo, 
         # 1. randomForest model 생성 및 Importance 계산
         rf ={
           
           rf_fit  <- caret::train(      
             f         =  fml
             , data      = training
             , method    = "rf"
             , trControl = fitControl
             , verbose   = F)
           
           Imp.rf <- data.frame(varImp(rf_fit))
           Imp.rf <- data.frame('col_name' = row.names(Imp.rf), 'value' = Imp.rf[,1])
           save(rf_fit, file = paste0('randomForest_',Sys.Date(), '_', cv_k, '_',  cv_rep, '.RData'))  # rf 모델 저장
           write.csv(Imp.rf, 'Importance_rf.csv')                                                      # Importance   정보 저장
         },
         
         # 2. glmnet model 생성 및 Importance 계산
         glmnet ={
           grid    <-  expand.grid(.alpha=seq(0,1, by=.2), .lambda=seq(0.00,0.2, by=0.02))
           
           glm_fit <- caret::train(
             f      =  fml
             , data      = training
             , method    = "glmne1t"
             , trControl = fitControl
             , tuneGrid  = grid
           )
           
           Imp.glm <- varImp(glm_fit)
           Imp.glm <- Imp.glm$importance
           Imp.glm <- data.frame('col_name' = row.names(Imp.glm), 'value' = Imp.glm[,1]) %>% arrange(-value)
           
           Imp.glm %>% filter(value == 'cafe')
           
           save(glm_fit, file = paste0('glmnet_',Sys.Date(), '_', cv_k, '_',  cv_rep, '.RData')) # glmnet 모델 저장
           write.csv(Imp.glm, 'Importance_glmnet.csv')             # Importance   정보 저장
           
         }
         
  )}


##################################
########## Phase 2 ###############
##################################


objectName <- foreach(algo = sAlgo, .combine = cbind) %do% {
  
  # code 
  switch(algo, 
         # 1. randomForest model 생성 및 Importance 계산
         # 3. xgboost 
         # ** 독립변수에 수치형 변수만 가능. -> 즉, one-hot encoding 된 데이터만 가능하다는 얘기.
         xgboost = {
           
           # X_train = xgb.DMatrix(as.matrix(training_encoding[,-1]))
           # y_train = training_encoding[,1]
           # X_test  = xgb.DMatrix(as.matrix(testing_encoding[,-1]))
           # y_test  = testing_encoding[,1]
           
           xgbGrid <- expand.grid(nrounds = c(100,200),                                  # this is n_estimators in the python code above
                                  max_depth = c(10, 15, 20, 25),
                                  colsample_bytree = seq(0.5, 0.9, length.out = 5),
                                  eta = 0.1,
                                  gamma=0,
                                  min_child_weight = 1,
                                  subsample = 1
           )             
           
           
           xgb_model = train(
                                f       =  fmle,
                              data      = training_encoding,
                              trControl = fitControl,
                              method    = "xgbLinear"
                        )
           
           xgb_imp <- xgb.importance(feature_names = xgb_model$finalModel$feature_names,
                                     model = xgb_model$finalModel)
           
           
         },
         
         svm     = {
           
           svm_fit <- caret::train(   
             f           = fmle
             ,  data     = training_encoding
             , method    = "svmLinear2"
             , trControl = fitControl
             , tuneGrid  = NULL
           )
           
           Imp.svm <- varImp(svm_fit)
           Imp.svm <- Imp.svm$importance
           Imp.svm <- data.frame('col_name' = row.names(Imp.svm), 'value' = Imp.svm[,1]) %>% arrange(-value)
           
           save(svm_fit, file = paste0('svm_',Sys.Date(), '.RData')) # glmnet 모델 저장
           write.csv(Imp.svm, 'Importance_svm.csv')                  # Importance   정보 저장
           
         }
  )}
