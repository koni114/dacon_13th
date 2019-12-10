# Library 호출
require(dplyr);require(data.table);require(plotly)
require(httr);require(dplyr);require(jsonlite);
require(geosphere)

# 경로 설정
setwd("C:/r")
path.dir <- "./daconData/"

# 공통 함수 호출
# source(file = './05.dacon14_common.R')

########################################
## train, test data dataPreProcessing ##
########################################

# 사용한 데이터 불러오기 예시
train <- fread(paste0(path.dir, 'train.csv'), encoding = 'UTF-8')
test  <- fread(paste0(path.dir, 'test.csv'), encoding  = 'UTF-8')

# 데이터 구성. train/test : 2:1
# nrow(train) # 415,423 row : train
# nrow(test)  # 228,170 row : test

# train_head <- head(train, 100)
# test_head  <- head(test,  100)

# 파생변수 생성 ----

# 1. train_test ----
test[,'train_test']  <- 'test'
train[,'train_test'] <- 'train'

# 2. 요일 컬럼 생성 : weekdays ----

full.data <- data.frame(dplyr::bind_rows(train, test))

# full.data를 train, test를 구분 짓기 위해 train_test column 추가
# View(head(full.data))

## 결측치 확인 : 결측치 데이터 없음!!!!
# isNaRate(full.data)

## 데이터 타입 설정
# str(full.data)

## 3. id ----
full.data[,'id'] <- as.character(full.data[,'id'])

## 4. date ----
## 8월 31일 ~ 10월 15일 45일치 data. 
## 9월 01일 ~ 9월 31일 : train
## 10월 01일 ~ 10월 15일 : test

full.data[,'date'] <- as.Date(full.data[,'date'])

# summary(full.data[,'date'])

## 5. bus_route_id : 노선ID ----
full.data[,'bus_route_id'] <- as.character(full.data[,'bus_route_id'])

## 6. in_out : 시내버스, 시외버스 구분 ----
# 1 시내   632939
# 2 시외    10654
# full.data %>% group_by(in_out)  %>%  dplyr::summarise(n = n())

# full.data %>% filter(train_test == 'train') %>% group_by(in_out) %>% summarise(Mean = mean(X18.20_ride, na.rm = T))

in_out <- c('시외' = 2, '시내' = 1)
full.data$in_out <- as.integer(plyr::revalue(full.data$in_out, in_out))


## 5. station_code : 해당 승하차 정류소의 ID ----
full.data[,'station_code'] <- as.character(full.data[, 'station_code'])


# full.data %>% group_by(station_code) %>% dplyr::summarise(n = n()) %>% arrange(n)

## 6. station_name : 해당 승하차 정류소 이름 ----
# View(full.data %>% group_by(date, bus_route_id, station_code) %>% dplyr::summarise(n = n()) %>% arrange(n))

## 7. latitude : 해당 버스 정류장의 위도 ----


## 8. longitude : 해당 버스 정류장의 경도 ----


## 9. 파생변수 weekdays 생성 ----

full.data[,'weekdays'] <- weekdays(full.data$date)

## label encoding 수행
weekdays_encoder <- c(  '월요일' = 1
                      , '화요일' = 2
                      , '수요일' = 3
                      , '목요일' = 4
                      , '금요일' = 5
                      , "토요일" = 6
                      , '일요일' = 7
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


 ## 12. road_name 파생변수 생성 --- 
## station_code, station_name 별 data 추출 -> BusStation
BusStation <- full.data %>% group_by(  station_code
                       , station_name) %>%  dplyr::select(  station_code
                                                          , station_name
                                                          , latitude
                                                          , longitude) %>% dplyr::distinct() %>% data.frame



# Kakao API를 이용하여 지번 주소 생성. 컬럼명 : address_name
KAKAO_MAP_API_KEY = 'KakaoAK a7b6a2e93a595e7087061157089a4b36'
KAKAO_KEYWORD           <-  c('병원', '은행', '학교', '학원', '문화시설' ,'음식점' ,'카페', '빌딩', '아파트')
names(KAKAO_KEYWORD) <-  c('hospital', 'bank', 'school', 'academy', 'culture', 'food', 'cafe', 'building', 'apartment')


for(i in 1:nrow(BusStation)){
  
  if(i %% 100 == 0){
    print(paste0('i :', i))
  }
  axis_n <- BusStation[i, c('latitude', 'longitude')]
  
  x <- axis_n[2]
  y <- axis_n[1]
  
  res <- GET(url = 'https://dapi.kakao.com/v2/local/geo/coord2address.json',
             query = list(
               x = x,
               y = y
             ),
             add_headers(Authorization = KAKAO_MAP_API_KEY))

  addrs <- res %>% content(as = 'text') %>% fromJSON()

  addrs$documents$address$address_name
  # 
  # 시명 : city_name
  if(is.null(addrs$documents$address$region_2depth_name)){
    BusStation[i, 'city_name'] <- NA
  }else{
    BusStation[i, 'city_name'] <- addrs$documents$address$region_2depth_name
  }

  # 동명 : town_name
  if(is.null(addrs$documents$address$region_3depth_name)){
    BusStation[i, 'town_name'] <- NA
  }else{
    BusStation[i, 'town_name'] <- addrs$documents$address$region_3depth_name
  }

  # 만약 있으면, 지번 setting : address_no
  if(is.null(addrs$documents$address$main_address_no)){
    BusStation[i, 'address_no'] <- NA
  }else{
    BusStation[i, 'address_no'] <- addrs$documents$address$main_address_no
  }
  
  ## 해당 지역 근처,  핵심 건물들이 몇개 있는지 API 추출.
  ## 정류소 좌표를 기준으로 150m 근방에 핵심 건물들이 얼마나 있는지 확인.
  for(j in 1:length(KAKAO_KEYWORD)){
    BusStation[i, names(KAKAO_KEYWORD)[j]] <-  kakao_api_call(x, y, keyword = KAKAO_KEYWORD[j])  
  }
  
}

BusStation <- BusStation %>% mutate(city_name = ifelse(is.na(city_name), '0', city_name))
BusStation <- BusStation %>% mutate(town_name = ifelse(is.na(town_name), '0', town_name))
BusStation <- BusStation %>% mutate(address_no = ifelse(is.na(address_no), '0', address_no))

# BusStation 결과 Dataset 저장
save(BusStation, file="./daconData/결과데이터셋/BusStation.RData")
write.csv(BusStation, '/daconData/결과데이터셋/BusStation.csv', fileEncoding = 'UTF-8')

## 12. 좌표 데이터를 이용한 정류장 위치 확인
## 제주, 고산, 성산, 서귀포 측정소 위도, 경도 좌표를 기준으로 해당 거리를 측정하여 컬럼 4개 생성.
## dis_jeju, dis_gosan, dis_sungsan, dis_seoguipo

jeju     <- c( 126.52969, 33.51411)
gosan    <- c(126.16283 , 33.29382)
sungsan  <- c(126.880   , 33.38677)
seoguipo <- c(126.5653  , 33.24616)

dis_jeju     <- distm(BusStation[,c('longitude','latitude')],jeju, fun=distGeo) / 1000
dis_gosan    <- distm(BusStation[,c('longitude','latitude')], gosan, fun=distGeo) / 1000
dis_sungsan  <- distm(BusStation[,c('longitude','latitude')],sungsan, fun=distGeo) / 1000
dis_seoguipo <- distm(BusStation[,c('longitude','latitude')],seoguipo, fun=distGeo) / 1000

jeju_distance <- data.frame(dis_jeju, dis_gosan, dis_sungsan, dis_seoguipo)
BusStation    <- cbind(BusStation, jeju_distance[,'area_name', drop = F])
jeju_distance[,'area_name'] <-  colnames(jeju_distance)[apply(jeju_distance,1,which.min)]

save(BusStation, file = './daconData/결과데이터셋/BusStation.RData')

# BusStation RData load
load('./daconData/결과데이터셋/BusStation.RData')

BusStation    <- BusStation %>%  select_at(c('station_code', 'city_name'
                                             , 'town_name', 'address_no',  names(KAKAO_KEYWORD), 'dis_jeju', 'dis_gosan', 'dis_sungsan', 'dis_seoguipo', 'area_name'))


##  label encoding : city_name ----
##  ->  제주시 : 1, 서귀포시 : 2
city_name_encoder <- c(   '제주시'   = 1
                        , '서귀포시' = 2
)

BusStation$city_name <- as.factor(plyr::revalue(BusStation$city_name, city_name_encoder))


## 정류소별 승차 인원 평균 값으로
station_KM <- fread(paste0(path.dir, '/결과데이터셋/station_KM.csv'), encoding = 'UTF-8')
BusStation <- dplyr::inner_join(BusStation[, -19], clusterByStation[,c('town_name', 'K_M')])

save(BusStation, file = './daconData/결과데이터셋/BusStation.RData')

## 2. label encoding : town_name ----
## 총 186개의 label 존재
## -> 일단 one-hot encoding 해보자 안되면 다른 방법 모색

# 일단 label encoding 

townName_uni <- BusStation %>% group_by(town_name) %>% dplyr::summarise(n = n()) %>% arrange(n) %>%  dplyr::select(town_name)
townName_uni <- townName_uni %>% mutate(label = seq(1:nrow(townName_uni))) %>% data.frame()
town_name_encoder        <- townName_uni[,'label']
names(town_name_encoder) <- townName_uni[,'town_name']
BusStation$town_name     <- as.factor(plyr::revalue(BusStation$town_name, town_name_encoder))


full.data                <- dplyr::inner_join(full.data, BusStation, by = 'station_code')

# BusStation %>% select(town_name) %>% distinct()

# 강수량 파생변수 추가 : rainfall ----
# rainfall_data <- fread(paste0(path.dir, '강수량.csv'), encoding = 'UTF-8')
# colnames(rainfall_data) <- c('date', 'rainfall')
# rainfall_data           <- rainfall_data %>% data.frame
# rainfall_data[,'date']  <- as.Date(rainfall_data[,'date'])
# full.data               <- dplyr::inner_join(full.data, rainfall_data, by = 'date')

# 범주형 처리
full.data[,'weekdays'] <- as.factor(full.data[,'weekdays'])
full.data[,'holidays'] <- as.factor(full.data[,'holidays'])

###### 일별 정류소별 버스 운행 대수 #########


g_station              <- fread(paste0(path.dir, '/결과데이터셋/data_bus_vhc.csv'))
g_station$date         <- as.Date(g_station$date)
g_station$station_code <- as.character(g_station$station_code)
full.data              <- dplyr::inner_join(full.data, g_station, by = c("date" = "date", "station_code" = "station_code"))
save(full.data, file = './daconData/결과데이터셋/full_data_vhc_id.RData')
write.csv(full.data, './daconData/결과데이터셋/full_data.csv__vhc_id', fileEncoding = 'UTF-8')

clusterByStation <- full.data %>% filter(train_test == 'train') %>%  group_by(town_name) %>% dplyr::summarise(M = mean(X18.20_ride))
M.CLUST          <- kmeans(clusterByStation[,'M'], 5, nstart = 1000)
clusterByStation['K_M'] <- M.CLUST$cluster

## one-hot encoding 수행
# weekdays, holidays, city_name, town_name
one.hot.weekdays     <- model.matrix(~weekdays, data = full.data)[ , -1]
one.hot.city_name    <- model.matrix(~city_name, data = full.data)[ , -1]
# one.hot.town_name  <- model.matrix(~town_name, data = full.data)[ , -1]

full.data_oneHotEncoding <- cbind(full.data, one.hot.weekdays)
full.data_oneHotEncoding <- cbind(full.data_oneHotEncoding, one.hot.city_name)
# full.data_oneHotEncoding <- cbind(full.data_oneHotEncoding, one.hot.town_name)

save(full.data_oneHotEncoding, file="./daconData/결과데이터셋/full.data_oneHotEncoding.RData")

full.data_oneHotEncoding_jeju       <- full.data_oneHotEncoding %>% filter(area_name == 'dis_jeju')
full.data_oneHotEncoding_seoguipo   <- full.data_oneHotEncoding %>% filter(area_name == 'dis_seoguipo')
full.data_oneHotEncoding_gosan      <- full.data_oneHotEncoding %>% filter(area_name == 'dis_gosan')
full.data_oneHotEncoding_sungsan    <- full.data_oneHotEncoding %>% filter(area_name == 'dis_sungsan')

save(full.data_oneHotEncoding_jeju, file="./daconData/결과데이터셋/full.data_oneHotEncoding_jeju.RData")
save(full.data_oneHotEncoding_seoguipo, file="./daconData/결과데이터셋/full.data_oneHotEncoding_seoguipo.RData")
save(full.data_oneHotEncoding_gosan, file="./daconData/결과데이터셋/full.data_oneHotEncoding_gosan.RData")
save(full.data_oneHotEncoding_sungsan, file="./daconData/결과데이터셋/full.data_oneHotEncoding_sungsan.RData")

write.csv(full.data_oneHotEncoding_jeju, './daconData/결과데이터셋/full.data_oneHotEncoding_jeju.csv', fileEncoding = 'UTF-8')
write.csv(full.data_oneHotEncoding_seoguipo, './daconData/결과데이터셋/full.data_oneHotEncoding_seoguipo.csv', fileEncoding = 'UTF-8')
write.csv(full.data_oneHotEncoding_gosan, './daconData/결과데이터셋/full.data_oneHotEncoding_gosan.csv', fileEncoding = 'UTF-8')
write.csv(full.data_oneHotEncoding_sungsan, './daconData/결과데이터셋/full.data_oneHotEncoding_sungsan.csv', fileEncoding = 'UTF-8')


# 날씨 데이터를 통해 추가 파생변수 생성(온도, 강수량)
# 1. 데이터 reading
# rain_temp <- fread(paste0(path.dir, 'rain_temp.csv'), encoding = 'UTF-8')
# head(rain_temp)
# as.Date(rain_temp$일시, '%Y-%m-%d %H:%M')

########################################
########################################