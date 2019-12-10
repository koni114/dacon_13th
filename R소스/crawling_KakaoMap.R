# kakaoMap API를 이용하여 위도, 경도를 주소로 변경하기 **
# 다음 지도는 일별 한도가 30만건!

library(httr)
library(dplyr)
library(jsonlite)

# 다음 지도 APP KEY를 환경설정에 저장하는 방법
KAKAO_MAP_API_KEY = 'KakaoAK a7b6a2e93a595e7087061157089a4b36'

# 위경도 좌표 지정
for(i in 1:nrow()){
  axis_n <- full.data[i, c('latitude', 'longitude')]
  
  x <- 170.12
  y <- 35.43
  
  x <- axis_n[2]
  y <- axis_n[1]
  # keyword <- c('405000367')
  # https://dapi.kakao.com/v2/local/search/keyword.json
  # https://dapi.kakao.com/v2/local/geo/coord2address.json
  res <- GET(url = 'https://dapi.kakao.com/v2/local/geo/coord2address.json',
             query = list(
               # query = keyword,
               x = x,
               y = y
               # radius = 1000,
               # sort = 'distance'
             ),
             add_headers(Authorization = KAKAO_MAP_API_KEY))
  
  addrs <- res %>% content(as = 'text') %>% fromJSON()
  addrs$documents
}



## 도로명주소 API 추출
DORO_MAP_API_KEY = "devU01TX0FVVEgyMDE5MTEyNTEzMjExODEwOTIxNzI="

res <- GET(url = 'http://www.juso.go.kr/addrlink/addrLinkApi.do',
           query = list(
             keyword = '33.48990  126.4937',
             resultType = 'json',
             currentPage = 1,
             countPerPage = 10,
             confmKey = DORO_MAP_API_KEY
           )
)

addrs <- res %>% content(as = 'text') %>% fromJSON()
data <- addrs$results
data$juso$rn
