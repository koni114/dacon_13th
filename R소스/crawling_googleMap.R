library(ggmap)
register_google( key = 'AIzaSyCAIi-ARCLrIxp3vNAZio68bpjxPzJ3e-M')
gc <- as.numeric(geocode('한라 병원'))


revgeocode(
    gc
  , output = 'address'
)


numVar <- c()
gc <- as.numeric(geocode('Baylor University'))


as.numeric(dfLocation[3,])

full.data.test <- full.data[1:100, ]

test <- full.data.test %>% group_by(station_name) %>% select(station_name, latitude, longitude) %>% distinct
i <- 1
for(i in 1:20){
  
  x <- test[i, ]
  latitude_n  <- x$latitude
  longitude_n <- x$longitude
  tt <- revgeocode(
    c(longitude_n, latitude_n)
    , output = 'all'
  )
  print(tt$results[[1]])
}


axisToAdress <- function(){
  
  
  
  
}




