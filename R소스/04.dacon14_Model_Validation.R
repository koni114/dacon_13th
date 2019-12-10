## Feature Engineering Script ##

# 1. 경로 설정
setwd("C:/r")
path.dir <- "./daconData/결과데이터셋/"
source(file = './05.dacon14_common.R')

# 2. 라이브러리 호출
require(caret);require(dplyr);require(mlbench);require(e1071);require(data.table)
require(klaR);require(pls);require(ipred);require(randomForest);require(sampling);require(glmnet)
require(xgboost);require(randomForest);require(caret)

#####################################
######### random Forest #############
#####################################

# 1. FE를 마친 Dataset 호출
load(paste0(path.dir, 'full_data.RData'))
# full.data <- fread(paste0(path.dir, 'full_data.csv'), encoding = 'UTF-8')


# 2. train, test 분할
training <- full.data %>%  filter(train_test == 'train')
testing  <- full.data %>%  filter(train_test == 'test')


# 3.1 혹시 모르니, training, testing 뒤섞어 주기.
set.seed(100)
training <- training[sample(1:nrow(training)), ]
testing <- testing[sample(1:nrow(testing)), ]

Yvar    <- c('X18.20_ride')
Xvar    <- c(  'in_out'
             , 'latitude'
             , 'longitude'
             , 'weekdays'          # 범주
             , 'holidays'          # 범주
             , 'X6.8_ride'
             , 'X8.10_ride'
             , 'X10.12_ride'
             , 'X6.8_takeoff'
             , 'X8.10_takeoff'
             , 'X10.12_takeoff'
             # , 'city_name'         # 범주
             # , 'town_name'         # 범주
             , 'hospital'
             , 'bank'
             , 'school'
             , 'academy'
             , 'culture'
             , 'food'
             , 'cafe'
             , 'building'
             , 'apartment'
             , 'dis_jeju'
             , 'dis_gosan'
             , 'dis_sungsan'
             , 'dis_seoguipo')

# 5. formula 생성
fml         <- formula(paste0(Yvar, " ~ ", paste(paste(Xvar, collapse =' + ')))) 

# 6. cross-validation 10-fold , 반복 5번 ==> 총 50번 
cv_k   = 3
cv_rep = 2
fitControl <- trainControl(method    = "repeatedcv"
                           , number  = cv_k)
# 7. customGrid 수행
# customGrid <- expand.grid(mtry = c(1, 5, 10))  

# 8. Model 생성
rf_fit  <- caret::train(      
        f          =  fml
      , data       = training
      , method     = "rf"
      , trControl  = fitControl
      # , tuneGrid   = customGrid
      , importance = T
      , verbose    = F)

Imp.rf <- data.frame(varImp(rf_fit))
Imp.rf <- data.frame('col_name' = row.names(Imp.rf), 'value' = Imp.rf[,1])
save(rf_fit, file = paste0('randomForest_',Sys.Date(), '_', cv_k, '_',  cv_rep, '.RData'))  # rf 모델 저장
write.csv(Imp.rf, 'Importance_rf.csv')                                                      # Importance   정보 저장


###############################
######### XGBOOST #############
###############################

# 1. FE된 Dataset 호출
# xgboost model은 수치형 독립변수만 가능 
# 따라서, oneHot Encoding 된 변수 사용해야함

load(paste0(path.dir, 'full_data_oneHotEncoding.RData'))
# full.data <- fread(paste0(path.dir, 'full_data_oneHotEncoding.csv'), encoding = 'UTF-8')

# 3. train, test 분할
training_encoding <- full.data_oneHotEncoding %>%  filter(train_test == 'train')
testing_encoding  <- full.data_oneHotEncoding %>%  filter(train_test == 'test')


# 3.1 혹시 모르니, training, testing 뒤섞어 주기.
set.seed(100)
training_encoding <- training_encoding[sample(1:nrow(training_encoding)), ]
testing_encoding  <- testing_encoding[sample(1:nrow(testing_encoding)), ]

# 4. 종속변수, 독립변수 setting
# 변수가 워낙 많으므로, 제외변수를 만들어 그 변수를 제외한 나머지 변수를 독립변수로 setting.
# 이때 종속변수가 독립변수에 들어가지 않도록 조심!

Yvar        <- c('X18.20_ride')
exclude.var <- c(    "id" 
                   , "date"
                   , "bus_route_id"
                   , "station_code"
                   , "station_name"
                   , "X6.7_ride"
                   , 'weekdays'
                   , 'city_name'     
                   , "X7.8_ride"
                   , "X8.9_ride"
                   , "X9.10_ride" 
                   , "X10.11_ride"
                   , "X11.12_ride"
                   , "X6.7_takeoff"
                   , "X7.8_takeoff"
                   , "X8.9_takeoff"
                   , "X9.10_takeoff" 
                   , "X10.11_takeoff"
                   , "X11.12_takeoff"
                   , "X18.20_ride" 
                   , "train_test" 
                   , "town_name"
                   , "address_no")  

Xvar        <- colnames(full.data_oneHotEncoding)[!colnames(full.data_oneHotEncoding) %in% c(Yvar, exclude.var)]

# 5. custom Grid 생성
# xgboost는 paramTuning에 영향을 많이 받는다고 알려져 있음.
# 어떤 hyper parameter인지를 정확하게 알고 사용해야함 ! 

xgbGrid <- expand.grid(nrounds = c(100,200),      # boosting round를 결정. 랜덤하게 생성되는 모델이니 만큼 이 수가 적당히 큰 게 좋음. epoch 옵션과 동일.
                       max_depth = c(10, 15, 20), # 한 트리의 maximum depth. 숫자를 키울수록 모델의 복잡도는 커짐. 과적합 하기 쉬움. 디폴트는 6.이때 리프 노드의 개수는 최대 64
                       colsample_bytree = seq(0.5, 0.9, length.out = 3),   # 나무를 생성할 때  샘플링하는 열의 비율
                       eta = seq(0.1, 0.5, length.out = 8),                # learning rate, 트리에 가지가 많을수록 과적합 되기 쉬움.
                       gamma = 0                                           # information gain에서 -r로 표현한바 있음. 이것이 커지면 트리 깊이가 줄어들어 보수적인 모델이 됨
)             

fmle         <- formula(paste0(Yvar, " ~ ", paste(paste(Xvar, collapse =' + ')))) 

cv_k   = 3
cv_rep = 2
fitControl <- trainControl(method    = "repeatedcv"
                           , number  = cv_k)


xgb_model = train(
  f         =  fmle,
  data      =  training_encoding[1:100,],
  trControl =  fitControl,
  method    =  "xgbLinear"
)


xgb_imp <- xgb.importance(feature_names = xgb_model$finalModel$feature_names,
                          model = xgb_model$finalModel)

xgb_imp <- xgb_imp %>% data.frame()
save(xgb_model, file = paste0('xgb_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
write.csv(xgb_imp, 'Importance_xgb.csv')            



######################
### glmnet model #####
######################


# 3. train, test 분할
training_encoding <- full.data_oneHotEncoding %>%  filter(train_test == 'train')
testing_encoding  <- full.data_oneHotEncoding %>%  filter(train_test == 'test')


# 3.1 혹시 모르니, training, testing 뒤섞어 주기.
set.seed(100)
training_encoding <- training_encoding[sample(1:nrow(training_encoding)), ]
testing_encoding  <- testing_encoding[sample(1:nrow(testing_encoding)), ]


Yvar        <- c('X18.20_ride')
exclude.var <- c(    "id" 
                   , "date"
                   , "bus_route_id"
                   , "station_code"
                   , "station_name"
                   , "X6.7_ride"
                   , 'weekdays'
                   , 'city_name'     
                   ,"X7.8_ride"
                   , "X8.9_ride"
                   , "X9.10_ride" 
                   ,  "X10.11_ride"
                   ,  "X11.12_ride"
                   ,  "X6.7_takeoff"
                   ,  "X7.8_takeoff"
                   ,  "X8.9_takeoff"
                   , "X9.10_takeoff" 
                   ,"X10.11_takeoff"
                   , "X11.12_takeoff"
                   , "X18.20_ride" 
                   , "train_test" 
                   , "town_name"
                   , "address_no")  

Xvar        <- colnames(full.data_oneHotEncoding)[!colnames(full.data_oneHotEncoding) %in% c(Yvar, exclude.var)]

fmle         <- formula(paste0(Yvar, " ~ ", paste(paste(Xvar, collapse =' + ')))) 

# 5. gridControl setting
grid    <-  expand.grid(.alpha=seq(0,1, by=.2), .lambda=seq(0.00,0.2, by=0.02))

cv_k   = 3
cv_rep = 2
fitControl <- trainControl(method    = "repeatedcv"
                           , number  = cv_k
                           , repeats = cv_rep)


glm_fit <- caret::train(
  f           =  fmle
  , data      = training_encoding[1:1000, ]
  , method    = "glmnet"
  , trControl = fitControl
  , tuneGrid  = grid
)

Imp.glm <- varImp(glm_fit)
Imp.glm <- Imp.glm$importance
Imp.glm <- data.frame('col_name' = row.names(Imp.glm), 'value' = Imp.glm[,1]) %>% arrange(-value)


save(glm_fit, file = paste0('glmnet_',Sys.Date(), '_', cv_k, '_',  cv_rep, '.RData')) # glmnet 모델 저장
write.csv(Imp.glm, 'Importance_glmnet.csv')             # Importance   정보 저장