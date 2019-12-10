isNaRate <- function(df){
  apply(df, 2, function(x){
    sum(is.na(x) | trimws(x, which = c("both")) == '') / length(x)
  })
}


DORO_name <- function(){
  
  DORO_MAP_API_KEY = "devU01TX0FVVEgyMDE5MTEyNTEzMjExODEwOTIxNzI="
  for(i in 1:nrow(BusStation)){
    
    address_name <- BusStation[i, c('address_name')]
    
    res <- GET(url = 'http://www.juso.go.kr/addrlink/addrLinkApi.do',
               query = list(
                 keyword = address_name,
                 resultType = 'json',
                 currentPage = 1,
                 countPerPage = 10,
                 confmKey = DORO_MAP_API_KEY
               )
    )
    
    addrs <- res %>% content(as = 'text') %>% fromJSON()
    data <- addrs$results
    data$juso$rn
  }
}


srswor_sampling <- function(df, nrate = NA, strVar = NA, Var = NA){
  
  if(is.na(nrate)) nrate <- 0.3
  if(is.na(strVar)) strVar <- 'date'
  
  full.data.idx <- df %>% group_by_at(strVar) %>% dplyr::summarise(n = n()*0.2) %>% data.frame 
  full.data.idx[, 'n'] <- round(full.data.idx[, 'n'], 0)
  x                <- strata(c(strVar), size = full.data.idx[, 'n'], method = "srswor", data = df)
  full.data.sample <- getdata(df, x)
  full.data.sample <- full.data.sample %>% select_at(Var)
  full.data.sample
}

kakao_api_call <- function(x = NA, y = NA,  keyword = NA){
  
  
  res <- GET(url = 'https://dapi.kakao.com/v2/local/search/keyword.json',
             query = list(query = (keyword), 
                          x = x,
                          y = y,
                          radius = 150,       # 중심점으로부터 반경 (단위:미터)
                          page = 10,            # 이동 가능한 페이지 : 1 ~ 45
                          size = 15,           # 페이지당 검색 결과 : 1 ~ 15
                          sort = 'distance'    # 'accuracy' or 'distance'
             ),
             add_headers(Authorization = KAKAO_MAP_API_KEY))
  addrs <- res %>% content(as = 'text') %>% fromJSON()
  return(addrs$meta$total_count)
  
}


