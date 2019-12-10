# Library 호출
require(dplyr);require(data.table);require(plotly)
require(httr);require(dplyr);require(jsonlite);
require(geosphere)
require(caret);require(dplyr);require(mlbench);require(e1071);require(data.table)
require(klaR);require(pls);require(ipred);require(randomForest);require(sampling);require(glmnet)
require(xgboost);require(randomForest);require(caret)

list.files(path = "../input/dacon-14th/")
path.dir <- "../input/dacon-14th/"

train <- fread(paste0(path.dir, 'train.csv'), encoding = 'UTF-8')
test  <- fread(paste0(path.dir, 'test.csv'), encoding  = 'UTF-8')

test[,'train_test'] <- 'test'
train[,'train_test'] <- 'train'

full.data <- data.frame(dplyr::bind_rows(train, test))

## 1. id ----
full.data[,'id'] <- as.character(full.data[,'id'])

## 2. date ----
## 8월 31일 ~ 10월 15일 45일치 data. 
## 9월 01일 ~ 9월 31일 : train
## 10월 01일 ~ 10월 15일 : test

full.data[,'date'] <- as.Date(full.data[,'date'])

## 3. bus_route_id : 노선ID ----
full.data[,'bus_route_id'] <- as.character(full.data[,'bus_route_id'])

## 4. in_out : 시내버스, 시외버스 구분 ----
# 1 시내   632939
# 2 시외    10654
in_out <- c('시외' = 2, '시내' = 1)
full.data$in_out <- as.integer(plyr::revalue(full.data$in_out, in_out))

## 5. station_code : 해당 승하차 정류소의 ID ----
full.data[,'station_code'] <- as.character(full.data[, 'station_code'])

## 6. 파생변수 weekdays 생성 ----
full.data[,'weekdays'] <- weekdays(full.data$date)

# ## label encoding 수행
weekdays_encoder <- c(  'Monday' = 1
                        , 'Tuesday' = 2
                        , 'Wednesday' = 3
                        , 'Thursday' = 4
                        , 'Friday' = 5
                        , "Saturday" = 6
                        , 'Sunday' = 7
)

full.data$weekdays <- as.integer(plyr::revalue(full.data$weekdays, weekdays_encoder))

## 10. 공휴일 파생변수 생성 ---
## 공휴일인 경우 vs 공휴일이 아닌경우에 대한 인원 통계 데이터 확인 필요

## 10, 11월 공휴일 날짜 데이터 : 공휴일, 토요일, 일요일
holidays <- as.Date(c('2019-09-01', '2019-09-07', '2019-09-08', '2019-09-12', '2019-09-13'
                      , '2019-09-14', '2019-09-15', '2019-09-21', '2019-09-22', '2019-09-28'
                      , '2019-09-29', '2019-10-03', '2019-10-05', '2019-10-06', '2019-10-09'
                      , '2019-10-12', '2019-10-13', '2019-10-19', '2019-10-20', '2019-10-26', '2019-10-27'))

full.data <- full.data %>% mutate(holidays = ifelse(date %in% holidays, '1', '0'))

## 11. 1시간별 승 하차 인원 컬럼을 2시간으로 병합 ----
full.data <- full.data %>% mutate(
  X6.8_ride       =  (X6.7_ride + X7.8_ride),
  X8.10_ride      =  (X8.9_ride + X9.10_ride),
  X10.12_ride     =  (X10.11_ride + X11.12_ride),
  X6.8_takeoff    =  (X6.7_takeoff + X7.8_takeoff),
  X8.10_takeoff   =  (X8.9_takeoff + X9.10_takeoff),
  X10.12_takeoff  =  (X10.11_takeoff +  X11.12_takeoff)
)

load( "../input/dacon-13th-busstation/BusStation.RData")
KAKAO_KEYWORD           <-  c('병원', '은행', '학교', '학원', '문화시설' ,'음식점' ,'카페', '빌딩', '아파트')
names(KAKAO_KEYWORD)    <-  c('hospital', 'bank', 'school', 'academy', 'culture', 'food', 'cafe', 'building', 'apartment')
BusStation              <- BusStation %>%  select_at(c('station_code', 'city_name'
                                             , 'town_name', 'address_no',  names(KAKAO_KEYWORD), 'dis_jeju', 'dis_gosan', 'dis_sungsan', 'dis_seoguipo', 'area_name'))

# town_name encoding
townName_uni <- BusStation %>% group_by(town_name) %>% dplyr::summarise(n = n()) %>% arrange(n) %>%  dplyr::select(town_name)
townName_uni <- townName_uni %>% mutate(label = seq(1:nrow(townName_uni))) %>% data.frame()
town_name_encoder        <- townName_uni[,'label']
names(town_name_encoder) <- townName_uni[,'town_name']
BusStation$town_name     <- as.factor(plyr::revalue(BusStation$town_name, town_name_encoder))

full.data  <- dplyr::inner_join(full.data, BusStation, by = 'station_code')

# 범주형 처리
full.data[,'weekdays'] <- as.factor(full.data[,'weekdays'])
full.data[,'holidays'] <- as.factor(full.data[,'holidays'])

###### 일별 정류소별 버스 운행 대수 추가 #########
g_station <- fread('../input/dacon-13th-vhc/data_bus_vhc.csv', encoding = 'UTF-8')
g_station$date         <- as.Date(g_station$date)
g_station$station_code <- as.character(g_station$station_code)

full.data <- dplyr::left_join(full.data, g_station, by = c("date" = "date", "station_code" = "station_code"))

full.data[,'vhc_id'] <- ifelse(is.na(full.data[,'vhc_id']), 0, full.data[,'vhc_id'])

YvalueByStation  <- full.data  %>% filter(train_test == 'train')  %>%  group_by(station_code)  %>% dplyr::summarise(
  MEAN = mean(X18.20_ride, na.rm = T),
  VAR  = var(X18.20_ride)
)
YvalueByStation[which(is.na(YvalueByStation$VAR)), 'VAR'] <- 0

station_zero   <- YvalueByStation  %>% filter(MEAN == 0)  %>%  dplyr::select(station_code)  %>%  unlist  %>%  unname

# one_hot encoding 수행
test_zero      <-  full.data   %>% filter(train_test == 'test' & station_code %in% station_zero)  %>% dplyr::select(id)  %>%  unlist  %>%  unname
full.data.test <-  full.data   %>% filter(!(station_code %in% station_zero))

one.hot.weekdays     <- model.matrix(~weekdays, data = full.data.test)[ , -1]
one.hot.city_name    <- model.matrix(~city_name, data = full.data.test)[ , -1]

full.data_oneHotEncoding <- cbind(full.data.test, one.hot.weekdays)
full.data_oneHotEncoding <- cbind(full.data_oneHotEncoding, one.hot.city_name)

YvalueByStation_NonZero <- YvalueByStation  %>% filter(MEAN != 0)
M.CLUST                 <- kmeans(YvalueByStation_NonZero[,-1], 5, nstart = 1000)
YvalueByStation_NonZero['K_M'] <- M.CLUST$cluster

full.data_oneHotEncoding   <- dplyr::left_join(full.data_oneHotEncoding, YvalueByStation_NonZero[,c('station_code', 'K_M')])
full.data_oneHotEncoding  <- full.data_oneHotEncoding %>% mutate(K_M = ifelse(is.na(K_M),  which.max(M.CLUST$size), K_M))
full.data_oneHotEncoding_1 <- full.data_oneHotEncoding  %>% filter(K_M == 1)  
full.data_oneHotEncoding_2 <- full.data_oneHotEncoding  %>% filter(K_M == 2) 
full.data_oneHotEncoding_3 <- full.data_oneHotEncoding  %>% filter(K_M == 3)  
full.data_oneHotEncoding_4 <- full.data_oneHotEncoding  %>% filter(K_M == 4)  
full.data_oneHotEncoding_5 <- full.data_oneHotEncoding  %>% filter(K_M == 5)

# train / test 별로 data 분할(여기서 test 는 실제 맞춰야할 test data)
# 평가를 위한 test data는 생성 x
training_1 <- full.data_oneHotEncoding_1  %>%  filter(train_test == 'train')
testing_1  <- full.data_oneHotEncoding_1  %>%  filter(train_test == 'test')

training_2 <- full.data_oneHotEncoding_2  %>%  filter(train_test == 'train')
testing_2  <- full.data_oneHotEncoding_2  %>%  filter(train_test == 'test')

training_3 <- full.data_oneHotEncoding_3  %>%  filter(train_test == 'train')
testing_3  <- full.data_oneHotEncoding_3  %>%  filter(train_test == 'test')

training_4 <- full.data_oneHotEncoding_4  %>%  filter(train_test == 'train')
testing_4  <- full.data_oneHotEncoding_4  %>%  filter(train_test == 'test')

training_5 <- full.data_oneHotEncoding_5  %>%  filter(train_test == 'train')
testing_5  <- full.data_oneHotEncoding_5  %>%  filter(train_test == 'test')

set.seed(100)
training_1 <- training_1[sample(1:nrow(training_1)), ]
testing_1  <- testing_1[sample(1:nrow(testing_1)),   ]

training_2 <- training_2[sample(1:nrow(training_2)), ]
testing_2  <- testing_2[sample(1:nrow(testing_2)),   ]

training_3 <- training_3[sample(1:nrow(training_3)), ]
testing_3  <- testing_3[sample(1:nrow(testing_3)),   ]

training_4 <- training_4[sample(1:nrow(training_4)), ]
testing_4  <- testing_4[sample(1:nrow(testing_4)),   ]

training_5 <- training_5[sample(1:nrow(training_5)), ]
testing_5  <- testing_5[sample(1:nrow(testing_5)),   ]

Yvar    <- c('X18.20_ride')
Xvar    <- c(      'in_out'
                   ,  'latitude'
                   , 'longitude'
                   , 'weekdays2'          
                   , 'weekdays3'          
                   , 'weekdays4'          
                   , 'weekdays5'  
                   , 'weekdays6'          
                   , 'weekdays7'          
                   , 'holidays'           # 범주
                   , 'X6.8_ride'
                   , 'X8.10_ride'
                   , 'X10.12_ride'
                   , 'X6.8_takeoff'
                   , 'X8.10_takeoff'
                   , 'X10.12_takeoff'
                   , 'city_name1'
                   , 'city_name2'
                   , 'city_name'         # 범주
                   , 'town_name'         # 범주
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
                   , 'dis_seoguipo'
                   , 'vhc_id')

fmle         <- formula(paste0(Yvar, " ~ ", paste(paste(Xvar, collapse =' + '))))
fmle

xgbGrid <- expand.grid(nrounds = c(100,200),                               # boosting round를 결정. 랜덤하게 생성되는 모델이니 만큼 이 수가 적당히 큰 게 좋음. epoch 옵션과 동일.                                
                       max_depth = c(10, 15, 20),                          # 한 트리의 maximum depth. 숫자를 키울수록 모델의 복잡도는 커짐. 
                                                                           # 과적합 하기 쉬움. 디폴트는 6.이때 리프 노드의 개수는 최대 64
                       colsample_bytree = seq(0.5, 0.9, length.out = 3),   # 나무를 생성할 때  샘플링하는 열의 비율
                       eta = seq(0.1, 0.5, length.out = 8),                # learning rate, 트리에 가지가 많을수록 과적합 되기 쉬움.
                       gamma = 0                                           # information gain에서 -r로 표현한바 있음. 이것이 커지면 트리 깊이가 줄어들어 보수적인 모델이 됨
)

# cv_k   : k-fold에서의 k
# cv_rep : 반복횟수 
cv_k   = 3
cv_rep = 2
fitControl <- trainControl(method    = "repeatedcv"
                           , number  = cv_k)

xgb_model_1 = train(
  f         =  fmle,
  data      =  training_1,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_1[['results']]  %>% arrange(RMSE)  %>% head(1)

xgb_model_2 = train(
  f         =  fmle,
  data      =  training_2,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_2[['results']]  %>% arrange(RMSE) %>% head(1)

xgb_model_3 = train(
  f         =  fmle,
  data      =  training_3,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_3[['results']]  %>% arrange(RMSE)  %>%  head(1)

xgb_model_4 = train(
  f         =  fmle,
  data      =  training_4,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_4[['results']]  %>% arrange(RMSE)  %>%  head(1)

xgb_model_5 = train(
  f         =  fmle,
  data      =  training_5,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_5[['results']]  %>% arrange(RMSE)  %>% head(1)

save(xgb_model_1, file = paste0('Xvar_V22_1_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_2, file = paste0('Xvar_V22_2_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_3, file = paste0('Xvar_V22_3_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_4, file = paste0('Xvar_V22_4_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_5, file = paste0('Xvar_V22_5_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장

predicted_1           <- predict(xgb_model_1, testing_1)
predicted_1           <- ifelse(predicted_1 < 0, 0, predicted_1)
testing_1$X18.20_ride <- predicted_1
predicted_2           <- predict(xgb_model_2, testing_2)
predicted_2           <- ifelse(predicted_2 < 0, 0, predicted_2)
testing_2$X18.20_ride <- predicted_2
predicted_3           <- predict(xgb_model_3, testing_3)
predicted_3           <- ifelse(predicted_3 < 0, 0, predicted_3)
testing_3$X18.20_ride <- predicted_3
predicted_4           <- predict(xgb_model_4, testing_4)
predicted_4           <- ifelse(predicted_4 < 0, 0, predicted_4)
testing_4$X18.20_ride <- predicted_4
predicted_5           <- predict(xgb_model_5, testing_5)
predicted_5           <- ifelse(predicted_5 < 0, 0, predicted_5)
testing_5$X18.20_ride <- predicted_5

testData <- dplyr::bind_rows(testing_1, testing_2)
testData <- dplyr::bind_rows(testData, testing_3)
testData <- dplyr::bind_rows(testData, testing_4)
testData <- dplyr::bind_rows(testData, testing_5)

submission_data           <- testData[,c('id', 'X18.20_ride')]
submission_data           <- dplyr::bind_rows(submission_data, data.frame(id =test_zero, X18.20_ride = 0, stringsAsFactors = F))

colnames(submission_data) <- c('id', '18~20_ride')
submission_data <- submission_data %>%  arrange(id) %>% data.frame()
save(submission_data, file ='submission_data.RData')
write.csv(submission_data, 'submission_data.csv', fileEncoding = 'UTF-8', row.names = F)