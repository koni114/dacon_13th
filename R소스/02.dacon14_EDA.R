# Library 호출
require(corrplot);require(nortest);require(caret);require(e1071);require(ggmap);
require(httr);require(tidyverse);require(jsonlite);require(data.table)
setwd("C:/r")
path.dir <- "./daconData/"

full.data <- fread(paste0(path.dir, 'full_data.csv'), encoding = 'UTF-8' )

# 18~20시 승차 인원(y) 통계 값 확인 ----

dayPerYCount <- full.data %>% filter(train_test == 'train'
) %>% select(date, X18.20_takeoff) %>%  group_by(date
) %>% dplyr::summarize(count = sum(X18.20_ride),
                       mean  = mean(X18.20_ride, na.rm = T)
                       )


p <- plot_ly(
  x = dayPerYCount$date,
  y = dayPerYCount$count,
  name = "시간별 6~8 승차 통계 값",
  type = "bar"
)

hourPerSum <- apply(full.data[,numericVars], 2, function(x){
  sum(x)
})

# 18~20시 승차 인원 밀도 함수 확인 ----

y.data <- full.data %>% filter(train_test == 'train') %>% select(X18.20_ride) %>% unlist %>%  unname
density.y.data <- density(y.data_boxCox)

p <- plot_ly(    x = ~ density.y.data$x
               , y = ~ density.y.data$y
               , type = 'scatter'
               , mode = 'none'
               , name = '오후 6~8시 승차인원 밀도 함수'
               , fill = 'tozeroy'
               ,fillcolor = 'rgba(255,136,41, 0.8)'
)
print(p)

# 18~20시 승차 인원 정규성 검토 ----

length(y.data)

# 로그 변환 시, 

y.data_log  <- log(y.data + 1)

# 제곱근 변환 시,

y.data_sqrt <- sqrt(y.data + 1)

# Box-cox 변환 시,

test           <- caret::BoxCoxTrans(y.data+1)
y.data_boxCox  <- predict(test, y.data+1)


 ## Q-Q plot
par( mfrow = c(1,2))
qqnorm(y.data, main=" y.dataQ-Q plot of 18 ~ 20 승차 인원")
qqline(y.data)
 
qqnorm(y.data_boxCox, main="Q-Q plot of 18 ~ 20 승차 인원_boxCox")
qqline(y.data_boxCox)
 
# qqnorm(y.data_sqrt$y.data_sqrt, main="Q-Q plot of 18 ~ 20 승차 인원_sqrt")
# qqline(y.data_sqrt$y.data_sqrt)
par(mfrow = c(1,1))


# V. 18-20 ride 시간대 요일 별 통계량 확인 ---- 

weekdaysPer6To8Hour    <- full.data %>% filter(train_test == 'train'
) %>% select(weekdays, X18.20_ride
) %>% group_by(weekdays) %>%  dplyr::summarise(count = sum(X18.20_ride))

#' 월,화가 가장 많고, 토,일 인원이 상대적으로 작음
#' 해당 컬럼을 변수로 추가해야함

p <- plot_ly(
  x = reorder(weekdaysPer6To8Hour$weekdays, weekdaysPer6To8Hour$weekdays),
  y = weekdaysPer6To8Hour$count,
  name = "요일별 승차 18시 ~ 20시 통계 값",
  type = "bar"
)
print(p)


# 시간별 승,하차 통계 값 추출 ----
# 하차 인원 최대 : 8~9, 최소 : 6~7
# 승차 인원 최대 : 7~8, 최소 : 6~7
Var <- grep( "ride", colnames(full.data))
Var <- grep( "takeoff", colnames(full.data))

hourPerSum <- apply(full.data[, Var], 2, function(x){
  sum(x)
})

hourPerSum <- hourPerSum[!is.na(hourPerSum)]

p <- plot_ly(
  x = names(hourPerSum),
  y = order(hourPerSum, names(hourPerSum)),
  name = "시간별 승차 통계 값",
  type = "bar"
)
print(p)

## 해당 날짜의 승차 인원이 많으면 6시 ~ 8시 승차 인원이 많을까? 
## 상관 분석 실시 ----
full.data.test <- full.data
colnames(full.data.test)
rideSum6to8 <- full.data.test  %>%  mutate(rideSum = X6.7_ride+ X7.8_ride+ X8.9_ride+ X9.10_ride+ X10.11_ride+ X11.12_ride
                                     ) %>% select(rideSum, X18.20_ride) 

cor.test(rideSum6to8$rideSum, rideSum6to8$X18.20_ride)



# 오전 6~12시의 승,하차 인원 vs 오후 6~8시 상관 계수 계산 ----

full.data.test <- full.data %>% filter(train_test == 'train')
numericVars <- which(sapply(full.data, is.numeric))
numericVarNames <- full.data %>% select_if(is.numeric) %>% colnames
cat('There are', length(numericVarNames), 'numeric variables')

# 
all_numVar <- full.data %>% select(numericVarNames)
cor_numVar <- cor(all_numVar, use = "pairwise.complete.obs") # 전 numeric 변수의 상관 계수
cor_sorted <- as.matrix(sort(cor_numVar[, 'X18.20_ride'], decreasing = TRUE))

# 3.2. 상관계수가 큰 변수만을 선택해보자 ----
CorHigh    <- names(which(apply(cor_sorted, 1, function(x) abs(x) > 0.5)))
cor_numVar <- cor_numVar[CorHigh, CorHigh]

corrplot.mixed(cor_numVar,
               tl.col = 'black', # 변수명 색깔
               tl.pos = 'lt',    # 변수명 왼쪽 표시 ** -> 이거 좋네
               number.cex = .7)  # matrix안 상관계수 text 크기

# ggmap 사용
library(ggmap)
register_google(key='AIzaSyCAIi-ARCLrIxp3vNAZio68bpjxPzJ3e-M')

stadium = get_googlemap('jeju',
                        maptype = 'roadmap',
                        zoom = 10)

test <- full.data %>% filter(train_test == 'train') %>%  group_by(station_code
                                                                  , station_name
                                                                  , latitude
                                                                  , longitude) %>% summarise(mean = mean(X18.20_ride)) %>% arrange(-mean)

ggmap(stadium) +
  geom_point(data = data.frame(test),
             aes(x = longitude, y = latitude), color = 'red', size = 1)


## 정류소별 통계 그래프 ----
load('./daconData/결과데이터셋/full_data.RData')
townPerMean <- full.data %>% filter(train_test == 'train') %>%  group_by(town_name) %>% dplyr::summarise(value = mean(X18.20_ride
                                                                    , na.rm = T), lat = mean(latitude, na.rm = T), lon = mean(longitude, na.rm = T)) %>% arrange(-value)  %>% data.frame


p <- plot_ly(
  x = reorder(townPerMean$town_name, townPerMean$value),
  y = (townPerMean$value),
  name = '동별 정류소 개수 현황',
  type = "bar"
)
print(p)