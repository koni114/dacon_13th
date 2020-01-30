## Jeju BigData Competition - 퇴근시간 버스승차인원 예측

### Notice
* dacon_13회 분석 경진대회를 참여하여 최종 제출한 분석 인사이트 및 코드 정리
* 최종 스코어 RMSE : 2.17
* 등수 : private : 155등, public : 144등
  - 먼저 분석 방법에 대해서 정리하고, 왜 점수가 낮은지도 한번 생각해보자

### Contents
* 분석 최종 코드 정리
* 왜 점수가 낮았을까? 생각해보기
* 이번 분석 경진대회를 통해 얻은 것들
* 최종 결론

### 분석 최종 코드 정리
* 들어가기에 앞서, 크게 데이터 불러오기, 데이터 전처리, FE(Feature Engineering), 모델링 순으로 코드가 작성됨


#### 데이터 불러오기
* 해당 사이트에서 데이터를 다운로드 받을 수 있다 https://dacon.io/cpt13/228543
* 다운로드 받은 후 데이터를 로딩하면, 한글이 깨져있음
이런 경우에는 메모장으로 열어 UTF-8로 저장한 후, 엑셀에서 메모장을 불러온 후 저장하고 로딩하면 정상적이게 불러 올 수 있음

* 먼저 라이브러리와 path 설정을 해놓자.
~~~
# Library 호출
require(dplyr);require(data.table);require(plotly)
require(httr);require(dplyr);require(jsonlite);
require(geosphere) # ggmap을 그리기 위한 library
require(caret);require(dplyr);require(mlbench);require(e1071);require(data.table)
require(klaR);require(pls);require(ipred);require(randomForest);require(sampling);require(glmnet)
require(xgboost);require(randomForest);require(caret)

list.files(path = "../input/dacon-14th/")
path.dir <- "../input/dacon-14th/"
~~~
### Data loading
* 기본적으로 read.csv function 보다 data.table package내 fread function을 이용하면
  훨씬 더 빨리 데이터를 loading 할 수 있음
~~~
train <- fread(paste0(path.dir, 'train.csv'), encoding = 'UTF-8')
test  <- fread(paste0(path.dir, 'test.csv'), encoding  = 'UTF-8')
test[,'train_test']  <- 'test'
train[,'train_test'] <- 'train'
full.data <- data.frame(dplyr::bind_rows(train, test))
~~~
#### 1. id
* 데이터의 key가 되는 id column. 날짜별, 정류소별, 노선도별 key에 해당
* 문자형으로 변환한다
~~~
full.data[,'id'] <- as.character(full.data[,'id'])
~~~
#### 2. date
* 날짜 컬럼
* Date type으로 변환
~~~
full.data[,'date'] <- as.Date(full.data[,'date'])
~~~
#### 3. bus_route_id : 노선 ID
* 노선ID, 마찬가지로 문자형으로 변환
~~~
full.data[,'bus_route_id'] <- as.character(full.data[,'bus_route_id'])
~~~
#### 4. in_out : 시외버스, 시내버스로 구분
* 1 시내   632939
* 2 시외    10654
* label encoding 진행
~~~
in_out <- c('시외' = 2, '시내' = 1)
full.data$in_out <- as.integer(plyr::revalue(full.data$in_out, in_out))
~~~
#### 5. station_code : 해당 승하차 정류소의 ID
* 마찬가지로 문자형으로 변환
~~~
full.data[,'station_code'] <- as.character(full.data[, 'station_code'])
~~~

## 파생변수 생성 & Encoding
* 데이터 EDA를 통해 다양한 파생변수를 생성하였다.
* 결과적으로 파생변수의 상관계수가 높지 않아 모델의 성능을 많이 높이지 못했다.
* 개인적으로 영향인자일 것이라고 생각해서 기대를 많이 했지만 성능을 많이 높이지 못해서 아쉽다. 왜 그랬을까..?
* 일단 어떤 파생변수를 생성했는지 알아보자

#### 1. weekdays : 요일 변수
* 아무래도 퇴근 시간 승차 인원은 주말에는 적게 타고, 평일에는 많이 탈 것이라고 생각했다. 따라서 요일 변수를 파생변수로 생성하여 추가하였다
* label encoding을 진행하여 1~7이라는 숫자로 변경하였다
~~~
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
~~~
#### 2. holidays : 공휴일 변수
* 마찬가지로 공휴일인 경우, 퇴근 시간 승차 인원에 영향을 미칠 것이라 생각하여 추가하였다
* 기간자체가 길지 않으므로, hard coding해서 공휴일 변수를 추가하였다
* label encoding을 통해 공휴일이면 '1', 아니면 '0'으로 변환하였다
~~~
holidays <- as.Date(c('2019-09-01', '2019-09-07', '2019-09-08', '2019-09-12', '2019-09-13'
                      , '2019-09-14', '2019-09-15', '2019-09-21', '2019-09-22', '2019-09-28'
                      , '2019-09-29', '2019-10-03', '2019-10-05', '2019-10-06', '2019-10-09'
                      , '2019-10-12', '2019-10-13', '2019-10-19', '2019-10-20', '2019-10-26', '2019-10-27'))
full.data <- full.data %>% mutate(holidays = ifelse(date %in% holidays, '1', '0'))
~~~
#### 3. X6.8_ride ~ X10.12_takeoff
* 종속변수가 6~8시(2시간) 승차인원을 예측해야 하므로, 독립변수의 기간도 2시간 간격으로 파생변수를 생성하였다
~~~
full.data <- full.data %>% mutate(
  X6.8_ride       =  (X6.7_ride + X7.8_ride),
  X8.10_ride      =  (X8.9_ride + X9.10_ride),
  X10.12_ride     =  (X10.11_ride + X11.12_ride),
  X6.8_takeoff    =  (X6.7_takeoff + X7.8_takeoff),
  X8.10_takeoff   =  (X8.9_takeoff + X9.10_takeoff),
  X10.12_takeoff  =  (X10.11_takeoff +  X11.12_takeoff)
)
~~~
#### 4. 버스정류소별 파생변수 생성
* train/test 구분 없이 파생변수를 추가로 생성할 수 있게끔 하는 변수는 버스 정류소라고 판단하였다.
* 따라서 버스정류소별로 추가적인 외부 데이터를 생성하거나 기존 변수들을 활용하여 파생변수를 생성하였다.

#### 5. KaKaoMap API 활용
변수명 : hospital, bank, school, academy, culture, food, cafe, building, apartment
* 우선적으로 버스 정류소 100m 근방에 병원,은행,학교,학원 등 주요 시설의 개수가 많을수록 6~8시 승차 인원이 많을 수 있을것이라 판단하여 추가하였다.
* 결과적으로 상관계수를 확인해 보았는데, 상관도는 매우 낮아 최종 모델링 독립 변수에는 추가하지 않았다.

#### 6. 변수명 : town_name
* 해당 좌표가 포함되는 '동'을 파생변수로 추가하였다

#### 7. 중급 코드 변수 활용
변수명 : dis_jeju,	dis_gosan,	dis_sungsan,	dis_seoguipo,	area_name
* 데이콘에 업로드되어 올라와있는 중급 코드 내용을 활용하였다
* 제주, 고산, 성상, 서귀포시의 관측소 위도, 경도를 기준으로 거리를 계산하여 파생변수로 추가하였다
~~~
load( "../input/dacon-13th-busstation/BusStation.RData")
# head(BusStation)
KAKAO_KEYWORD           <-  c('병원', '은행', '학교', '학원', '문화시설' ,'음식점' ,'카페', '빌딩', '아파트')
names(KAKAO_KEYWORD) <-  c('hospital', 'bank', 'school', 'academy', 'culture', 'food', 'cafe', 'building', 'apartment')
BusStation    <- BusStation %>%  select_at(c('station_code', 'city_name'
                                             , 'town_name', 'address_no',  names(KAKAO_KEYWORD), 'dis_jeju', 'dis_gosan', 'dis_sungsan', 'dis_seoguipo', 'area_name'))
~~~

#### 8.  town_name Label encoding
* town_name의  범주형 변수를 우선적으로 label encoding을 진행한다.
* 결과적으로 쓰지 못했는데, 그 이유는 class 자체가 180개가 넘는 label class가 존재하고, 수행시간이 너무 오래걸려 제외하였다.
~~~
# town_name encoding
townName_uni <- BusStation %>% group_by(town_name) %>% dplyr::summarise(n = n()) %>% arrange(n) %>%  dplyr::select(town_name)
townName_uni <- townName_uni %>% mutate(label = seq(1:nrow(townName_uni))) %>% data.frame()
town_name_encoder        <- townName_uni[,'label']
names(town_name_encoder) <- townName_uni[,'town_name']
BusStation$town_name     <- as.factor(plyr::revalue(BusStation$town_name, town_name_encoder))
~~~
~~~
# 기존의 train/test dataset에 해당 파생변수를 추가한다
full.data  <- dplyr::inner_join(full.data, BusStation, by = 'station_code')
~~~
~~~
# 범주형 처리
full.data[,'weekdays'] <- as.factor(full.data[,'weekdays'])
full.data[,'holidays'] <- as.factor(full.data[,'holidays'])
~~~
#### 9. 일별 정류소별 버스 운행 대수 추가
변수명 : bus_vhc
* 기존 버스 카드 데이터를 이용하여 해당 버스 정류소의 버스 운행 대수를 추가하여 편성하였다.
~~~
###### 일별 정류소별 버스 운행 대수 추가 #########
g_station <- fread('../input/dacon-13th-vhc/data_bus_vhc.csv', encoding = 'UTF-8')
g_station$date         <- as.Date(g_station$date)
g_station$station_code <- as.character(g_station$station_code)
~~~
~~~
full.data <- dplyr::left_join(full.data, g_station, by = c("date" = "date", "station_code" = "station_code"))
full.data[,'vhc_id'] <- ifelse(is.na(full.data[,'vhc_id']), 0, full.data[,'vhc_id'])
~~~

#### 10. 정류소별 평균, 분산 통계량 확인
* 정류소별 평균과 분산 통계량을 확인하였다.
* 만약 종속변수(X18~20.ride)의 평균,분산 값이 0이라면 해당 정류소에는 test Dataset 종속변수 값도 0으로 판단할 수 있다.(모델은 그렇게 판단하지 않을 수 있으므로..)
* 따라서 해당 작업을 수행하도록 한다
~~~
YvalueByStation  <- full.data  %>% filter(train_test == 'train')  %>%  group_by(station_code)  %>% dplyr::summarise(
    MEAN = mean(X18.20_ride, na.rm = T),
    VAR  = var(X18.20_ride)
)
YvalueByStation[which(is.na(YvalueByStation$VAR)), 'VAR'] <- 0
~~~
~~~
station_zero   <- YvalueByStation  %>% filter(MEAN == 0)  %>%  dplyr::select(station_code)  %>%  unlist  %>%  unname
~~~
~~~
test_zero      <-  full.data   %>% filter(train_test == 'test' & station_code %in% station_zero)  %>% dplyr::select(id)  %>%  unlist  %>%  unname
full.data.test <-  full.data   %>% filter(!(station_code %in% station_zero))
~~~
#### 11. one-hot encoding 수행
* full.data 내에서는 범주형 데이터가 존재한다. 따라서 one-hot encoding을 우선적으로 수행하자
* 변환할 변수 : weekdays, city_name
~~~
one.hot.weekdays     <- model.matrix(~weekdays, data = full.data.test)[ , -1]
one.hot.city_name    <- model.matrix(~city_name, data = full.data.test)[ , -1]
~~~
~~~
full.data_oneHotEncoding <- cbind(full.data.test, one.hot.weekdays)
full.data_oneHotEncoding <- cbind(full.data_oneHotEncoding, one.hot.city_name)
~~~
#### 12. K-means를 통한 군집 생성
* 처음에는 고산, 성산, 제주, 서귀포 관측소 좌표를 기준으로 가까운 곳을 군집으로 하여 계산하였는데, 이는 종속변수를 고려하지 않은 구분이라고 판단하였다.
* 시각화를 수행해보면 물론 서귀포, 제주시에 많은 정류소와 비교적 높은 비율의 종속변수 값을 확인할 수 있지만,
* 이러한 방법이 더 좋은 성능을 가져다 줄 것이라 생각하여 군집을 추가하고, 군집별로 모델을 생성하였다. 군집기준은 정류소로 하였다.
~~~
YvalueByStation_NonZero <- YvalueByStation  %>% filter(MEAN != 0)
M.CLUST                 <- kmeans(YvalueByStation_NonZero[,-1], 5, nstart = 1000)
YvalueByStation_NonZero['K_M'] <- M.CLUST$cluster
~~~
~~~
full.data_oneHotEncoding   <- dplyr::left_join(full.data_oneHotEncoding, YvalueByStation_NonZero[,c('station_code', 'K_M')])
full.data_oneHotEncoding  <- full.data_oneHotEncoding %>% mutate(K_M = ifelse(is.na(K_M),  which.max(M.CLUST$size), K_M))
full.data_oneHotEncoding_1 <- full.data_oneHotEncoding  %>% filter(K_M == 1)
full.data_oneHotEncoding_2 <- full.data_oneHotEncoding  %>% filter(K_M == 2)
full.data_oneHotEncoding_3 <- full.data_oneHotEncoding  %>% filter(K_M == 3)
full.data_oneHotEncoding_4 <- full.data_oneHotEncoding  %>% filter(K_M == 4)
full.data_oneHotEncoding_5 <- full.data_oneHotEncoding  %>% filter(K_M == 5)
~~~
#### 13.train/test 분리, shuffling 진행
* train, test별로 다시 분리하고, 혹시 날짜별로 나열되어있는 경우를 생각해 shuffling을 진행하였다.
~~~
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
~~~
~~~
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
~~~

## 독립변수, 종속변수 선택 & Modeling
### 1. X, Y 편성
* Xvar, Yvar를 편성한다.
* 일반적으로 혐의인자탐지를 통해 독립변수의 중요로를 생각하여 setting하는 것이 일반적이다.
* 혐의인자탐지는 생략하였으나, 결과적으로 모든 변수를 추가하는 것이 좋다고 판단하여 필요한 변수들은 모두 추가하였다.
~~~
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

~~~
~~~
fmle         <- formula(paste0(Yvar, " ~ ", paste(paste(Xvar, collapse =' + '))))
~~~
### 2. XGBoost 수행
* 최종 모델은 XGBoost를 생성하였다.
* 해당 모델은 randomforest에 비해 성능이 빠르다고 알려져 있는 Boosting 앙상블 모델 중 하나이다.

#### 2.1 hyper parameter setting
* 먼저 hyper parameter를 setting 하였다.
* hyper parameter의 의미는 주석을 달아두었다.
~~~
xgbGrid <- expand.grid(nrounds = c(100,200),                               # boosting round를 결정. 랜덤하게 생성되는 모델이니 만큼 이 수가 적당히 큰 게 좋음. epoch 옵션과 동일.
                       max_depth = c(10, 15, 20),                          # 한 트리의 maximum depth. 숫자를 키울수록 모델의 복잡도는 커짐. 과적합 하기 쉬움. 디폴트는 6.이때 리프 노드의 개수는 최대 64
                       colsample_bytree = seq(0.5, 0.9, length.out = 3),   # 나무를 생성할 때  샘플링하는 열의 비율
                       eta = seq(0.1, 0.5, length.out = 8),                # learning rate, 트리에 가지가 많을수록 과적합 되기 쉬움.
                       gamma = 0                                           # information gain에서 -r로 표현한바 있음. 이것이 커지면 트리 깊이가 줄어들어 보수적인 모델이 됨
)
~~~

#### 2.2 cross-validation 수행
* 반복 횟수와 k-fold에서의 k 값을 setting 하였다.
~~~
# cv_k   : k-fold에서의 k
# cv_rep : 반복횟수
cv_k   = 3
cv_rep = 2
fitControl <- trainControl(method    = "repeatedcv"
                           , number  = cv_k)
~~~

#### 2.3 Model 생성
* 최종적으로 군집을 4개 만들었는데, 군집별로 XGBoost를 각각 생성하였다.
* package는 caret package를 사용하였다.
~~~
xgb_model_1 = train(
  f         =  fmle,
  data      =  training_1,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_1[['results']]  %>% arrange(RMSE)  %>% head(1)
~~~
~~~
xgb_model_2 = train(
  f         =  fmle,
  data      =  training_2,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_2[['results']]  %>% arrange(RMSE) %>% head(1)
~~~
~~~
xgb_model_3 = train(
  f         =  fmle,
  data      =  training_3,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_3[['results']]  %>% arrange(RMSE)  %>%  head(1)
~~~
~~~
xgb_model_4 = train(
  f         =  fmle,
  data      =  training_4,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_4[['results']]  %>% arrange(RMSE)  %>%  head(1)
~~~
~~~
xgb_model_5 = train(
  f         =  fmle,
  data      =  training_5,
  trControl =  fitControl,
  method    =  "xgbLinear"
)
xgb_model_5[['results']]  %>% arrange(RMSE)  %>% head(1)
~~~
~~~
save(xgb_model_1, file = paste0('Xvar_V22_1_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_2, file = paste0('Xvar_V22_2_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_3, file = paste0('Xvar_V22_3_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_4, file = paste0('Xvar_V22_4_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
save(xgb_model_5, file = paste0('Xvar_V22_5_',Sys.Date(), '_',cv_k, '_', cv_rep,'.RData')) # glmnet 모델 저장
~~~
~~~
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
~~~
~~~
testData <- dplyr::bind_rows(testing_1, testing_2)
testData <- dplyr::bind_rows(testData, testing_3)
testData <- dplyr::bind_rows(testData, testing_4)
testData <- dplyr::bind_rows(testData, testing_5)
~~~
~~~
submission_data           <- testData[,c('id', 'X18.20_ride')]
submission_data           <- dplyr::bind_rows(submission_data, data.frame(id =test_zero, X18.20_ride = 0, stringsAsFactors = F))
~~~
~~~
colnames(submission_data) <- c('id', '18~20_ride')
submission_data <- submission_data %>%  arrange(id) %>% data.frame()
save(submission_data, file ='submission_data.RData')
write.csv(submission_data, 'submission_data.csv', fileEncoding = 'UTF-8', row.names = F)
~~~

### 결론
#### 왜 점수가 낮았을까?
* station_code 를 변수로 넣지 않았던 점
* xgboost만을 고집. 1,2,3등 소스를 보면 lgbm을 main으로 모델을 만들어냄  
실제로는 시간이 부족함. 혼자 퇴근하고 하다보니.. (비겁한 변명)

* 날씨 데이터를 넣지 않았다.
* lag 값을 더 추가할 필요성이 있었음. 필자는 2시간 간격의 변수만 추가 했지만 1,2,3등 코드를 보면 3시간 간격의 변수도 추가함
