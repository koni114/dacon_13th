# R을 이용한 웹 크롤링
## 참고
* 해당 자료는 R웹크롤링기초 - 연세대학교대학원응용통계학과특강 자료를 정리해 놓은 것임을 밝힙니다  

## 웹크롤링
* 웹 페이지에서 보이는 데이터를 필요한 부분만 선택  
* 웹 크롤링에 사용되는 프로그램을 크롤러라고 함  
* 웹 크롤링은 웹 페이지에 따라 다르게 적용해야 함  
* 반드시알아두어야할기초  
  * HTTP통신, HTML요소, 인코딩방식  
* 크롬개발자도구사용법  
  * Elements탭에서HTML요소찾기  

## 웹크롤링 간단 이해
####  우리가 인터넷에서 정보를 검색하는 방법
* 클라이언트 - 웹 브라우저 - 웹 서버 - HTML 출력  
  - process 설명  
    - 클라이언트가 개인 노트북/데스크탑으로 웹 브라우저에 URL 입력을 함  
    - 웹 브라우저는 HTTP 통신 방식으로 웹 서버에 데이터 요청(request)를 함  
    - 웹 서버는 받은 호출 정보를 토대로 다시 HTTP 통신 방식으로 응답(response)를 해줌  
    - HTML 형식으로 정보를 출력함  

#### 웹 크롤링은 인터넷 검색과 유사
* ① HTTP Request (요청)  
  * GET방식과 POST방식의 HTTP 통신  
  * JavaScript 및 RSelenium 이용  
  * httr, urltools, RSelenium package 등 ..  

* ② HTTP Response (응답)  
  * 응답 결과 확인(상태코드, 인코딩 방식 등)  
  * 응답 받은 객체를 텍스트로 출력  
  * 응답 받은 객체에 찾는 HTML 포함 여부 확인  


* ③ HTML에서 데이터 추출  
  * 응답 받은 객체를 HTML로 변환  
  * CSS 또는 XPath로 HTML 요소 찾기  
  * HTML 요소로부터 데이터 추출  
  * rvest, jsonlite package 등..  

* ④ 데이터 전처리 및 저장  
  * 텍스트 전처리(결합, 분리, 추출, 대체)  
  * 다양한 형태로 저장 (RDS, RData, xlsx, csv 등)  

#### 웹 크롤링 관련 주의사항  
* 웹 페이지는 회사가 비즈니스를 영위할 목적으로 만든 것임  
* 웹 크롤링은 '영업권 및 지적재산권'을 침해하는 행위로 민사소송에 휘말릴 수 있음  
* 따라서 웹 크롤링 하려는 웹 사이트의 메인 페이지에서 사전에    
'robots.txt'를 확인해야 하며, 수집한 데이터를 영업에 사용할 목적이라면 반드시 법률검토를 진행 해야 함  

## HTTP 기초

#### HTTP(Hyper Text Transfer Protocol)
* '초본문 전송 규약'이라고 직역이 가능한데,  
인터넷(World Wide Web)에서 주로 사용되며, 주로 HTML를 주고 받음  
* 데이터를 주고 받는 당사자는 클라이언트와 웹 서버임  
* 클라이언트가 웹서버에 데이터를 요청(request)하고, 웹서버는 해당 요청에 대한 결과를 응답(response)함  
* 클라이언트가 요청할 때 사용할 수 있는 방식(Method)에는 여러 가지가 있으며, 가장 많이 사용되는 방식이 GET 방식과 POST 방식  

#### HTTP 요청(Request)
* 클라이언트가 웹서버에 HTTP를 요청할 때, 웹서버에 제공해야 하는 <b>메세지 방식</b>은 크게 GET방식과 POST방식으로 나뉨  
  - GET방식   
    * <b> 요청 라인</b>과 <b>요청 헤더</b>를 보내야 함  
    * 웹 브라우저의 주소창에서 보이는 URI만 가지고 웹 서버에 요청할 수 있는 간단한 방법  

  - POST방식 : 위 두가지에 메세지 바디를 추가해야 함  
    * 웹 브라우저의 주소창에서 보이는 URL로는 원하는 결과를 얻을 수 없으며,    
    크롬 개발자도구에서 관련 <b>URL과 Parameter를</b> 찾아야 하는 다소 복잡한 방식  

#### URI vs URL
* URI  
  * <b>Uniform Resources Indicator</b>의 약자로, 머리글자, 리소스를 식별하는 문자열들을 차례대로 배열 한 것  
* URL  
  * Uniform Resources Locator의 약자로 머리글자와 리소스의 위치를 의미. URL은 URI의 부분 집합이라고 생각하면 됨  

#### HTTP 응답(response)
* 웹 서버는 클라이언트에게 응답 메세지를 발송  
* 응답 메세지는 '응답 헤더'와 '응답 바디'로 구성  
  - 응답 헤더는 HTTP 버전, <b>응답 코드, 일시, 콘텐츠 형태, 인코딩 방식</b> 크기 등이 포함되며     
바디에는 HTML이 포함됨  

* 상태코드  
  * 1XX : 정보교환
  * 2XX : 데이터 전송 성공 or 수락됨
  * 3XX : 방향 바꿈
  * 4XX : 클라이언트 오류(주소 오류, 권한 없음, 접근 금지 등)
  * 5XX : 서버 오류(올바른 요청을 처리할 수 없음 등)  

#### HTML(Hyper Text Markup Language)
* 웹페이지의 제목, 단락, 목록 등 문서의 구조를 나타내는 마크업 언어  
* HTML은 꺽쇠 괄호 '<>' 안에 태그로 되어 있는 HTML 요소 형태로 작성  
* HTML의 디자인을 담당하는 CSS와 웹 브라우저를 제어하는 JavaScript를 함께 사용함으로써 상호작용하는 웹페이지를 구현할 수 있음  

#### 한글 인코딩이란?
* 한글 인코딩은 '한글을 컴퓨터에 표시하는 방식'을 말함  
* 사람들의 문자를 컴퓨터가 이해할 수 있도록 16진수로 표기한 것인 한글 인코딩임  
* 한글 인코딩에 주로 사용되는 방식은 크게 <b>EUC-KR</b>과 <b> UTF-8</b> 이 있음  
 ![img](https://github.com/koni114/daily_Tip/blob/master/image/%ED%95%9C%EA%B8%80%EC%9D%B8%EC%BD%94%EB%94%A9%EB%B0%A9%EC%8B%9D%EA%B4%80%EA%B3%84%EB%8F%84.JPG)  

#### 로케일(Locale) 이란?
* 국가마다 시간을 표기하는 방식이라던지, 숫자를 표기하는 방식 등  
차이가 있기 때문에 운영체제(OS)는 국가마다 서로 다른 Locale을 제공하고 있음  
* 로케일은 국가마다 다음과 같은 여러 가지 표기 형식을 설정하는 것  
  * LC_COLLATE(문자정렬), LC_CTYPE(문자처리), LC_MONETARY(통화)    
LC_NUMERIC(숫자), LC_TIME(날짜/시간), LC_MESSAGES(언어/문화) 등  

* 국가별 로케일 이름  
  * 대한민국  
    * Windows 일 때  
      * 로케일 이름 : korean  
      * 인코딩 방식 : CP949  
    * Mac 일 때  
      * 로케일 이름 : ko_KR  
      * 인코딩 방식 : UTF-8    

#### 퍼센트 인코딩이란?
* URL에 사용되는 문자를 인코딩하는 방식이며, URL 인코딩이라고도 함  
* 한글 인코딩 방식에 따라 결과가 달라짐  

* ex) "웹크롤링" 이라는 단어를 퍼센트 인코딩한 결과  
  * UTF-8    : %EC%9B%B9%ED%81%AC%EB%A1%A4%EB%A7%81  
  * EUC-KR : %C0%A5%C5%A9%B7%D1%B8%B5  

## 크롬 개발자도구 사용법
* Elements 탭에서 HTML 요소 찾는 방법  

#### 크롬 개발자도구를 사용하는 방법  
* '크롬 개발자도구'는 웹 페이지에서 수집하려는 내용을 담고 있는 HTML 요소를 찾거나, HTTP 요청 과정에서 클라이언트와 웹 서버 간 주고 받은 (사용자에게 보이지 않은) 리소스를 찾고자 할 때 사용  

* 크롬 도구에서 <b>'도구 더보기(More Tools) -> 개발자도구(Developer Tools)'</b> 를 선택(F12..)  

* 크롬 개발자도구에서 제공되는 탭은 Elements 외 8개지만, 이번 강의에서 Elements 와 Network만 사용  
 ![img](https://github.com/koni114/daily_Tip/blob/master/image/CSSSelector_XPath_1.JPG)  
  ![img](https://github.com/koni114/daily_Tip/blob/master/image/CSSSelector_XPath_2.JPG)  

## 관련 R 패키지 및 주요 함수 소개  
#### 웹 크롤링 관련 R 패키지 목록  
* HTTP 통신 : httr, RSelenium  
* HTML 요소 : rvest, jsonlite  
* 인코딩 관련 : urlTools, readr  
* 파이프 연산자 : magrittr (dplyr)  
* 텍스트 전처리 : stringr  

### HTTP 통신 관련 : httr 패키지 소개
* httr은 HTTP 요청 및 응답에 관한 작업에 사용되는 패키지
* 주요 함수  
  *  HTTP 요청에 관한 함수 : GET(), POST(), user_agent(), add_headers(), set_cookies()  
  * HTTP 응답에 관한 함수 : status_code(), content(), cookies(), headers()  
  * HTTP 응답에 성공하지 못했을 때 사용하는 함수들 : warn_for_status(), stop_for_status()  

#### httr 패키지 주요함수1 : GET 방식의 HTTP요청
~~~
res <-  GET(
    url   = '요청할 웹 페이지 URL',
    query = list(
      a = 'a에 할당된 값',
      b = 'b에 할당된 값'
    )      
)
~~~
* GET 방식의 HTTP 통신이 사용된 경우, GET() 함수를 사용  
* url 인자에 웹 페이지의 URL 부분을 할당하고    
query 인자에 query string을 list 형태로 할당  

#### httr 패키지 주요함수2 : POST 방식의 HTTP요청
~~~
res <-  POST(
    url   = '요청할 웹 페이지 URL',
    body = list('POST 방식 요청에 사용될 파라미터'),
    encode = c('multipart', 'form', 'json', 'raw')      
)
~~~
* POST 방식으로 HTTP 통신하는 경우에 POST() 를 사용  
* POST 함수는 query 인자 대신 body와 encode 인자를 추가  
* body와 encode 인자에 저장하는 값은 크롬 개발자도구의 네트워크 탭에서 찾음  
* encode의 경우 4가지 중 해당하는 한 가지를 선택하거나 생략할 수 있음  

#### httr 패키지 주요함수3 : 상태코드 및 응답 결과 확인
~~~
print(x = res)
~~~
* HTTP 응답 결과를 한 번에 출력

~~~
status_code(x = res)
~~~
* HTTP 응답 상태코드만 출력.    
사용자 정의 함수 등에서 유용하게 사용할 수 있음  

~~~
content(
    x        = res
  , as       = ‘text’
  , type     = ‘text/html’
  , encoding = ‘EUC-KR’
  )
~~~
* HTTP 응답 바디(HTML)를 텍스트 형태로 출력하여 육안으로 확인  
* encoding 인자는 추가하지 않아도 자동으로 설정  
* encoding 인자는 상황에 따라 반드시 추가해야 하는 경우가 있음  

### HTML 요소 관련 : rvest 패키지
* rvest는 웹 페이지로부터 데이터를 수집할 때 사용하는 패키지  
* 주요 함수는 다음과 같음  
  * 응답 객체를 HTML로 변환하는 함수 : read_html()  
  * HTML 요소를 추출하는 함수 : html_node(), html_nodes()  
  *  HTML 속성에 관련된 함수 : html_attr(), html_attrs(), html_name()  
  * 데이터를 추출하는 함수 : html_text(), html_table()  

#### rvest 패키지 주요 함수1: 응답 객체에서 HTML 읽기
~~~
html <- read_html(
    x        = res
  , encoding = 'UTF-8'
)
~~~
* HTTP 응답 객체인 res로 부터 HTML을 읽은 다음 html 객체에 할당  
* res 객체의 한글인코딩 방식을 지정해 주어야 함  
* res 객체의 한글 인코딩 방식을 확인하는 방법은 print(x=res)를 실행


#### rvest 패키지 주요 함수2 : HTML 요소 찾기
~~~
item <- html_node(
   x     = html
  ,css   = '크롬 개발자 도구에서 복사해온 CSSSelector'
  ,xpath = '크롬개발자도구에서복사해온Xpath'
  )
~~~
* html_node() 함수 인자중 `css`와 `xpath` 둘 중 하나만 사용하면 됨  
* html_node() 함수와 html_nodes()함수는 사용법이 같음.    
다른점은 html_node() 함수는 찾고자하는 HTML요소가 여러 개 있을때 맨 처음 하나만 가져오지만,  
html_nodes() 함수는 모든 HTML 요소를 가져옴. 따라서 일반적으로 html_nodes() 함수가 더 유용.  

#### rvest 패키지 주요 함수 3 : HTML에서 text 추출
~~~
text <- html_text(
      x    = item
    , trim = FALSE
    )
~~~
* HTML 요소 중 시작 태그와 종료 태그 사이에 있는 '웹 브라우저에 보이는 내용'을 수집할 때 사용  
* html_node 함수 또는 html_nodes 함수로 추출한 HTML 요소에 있는 모든 text를 추출  
* `trim` 인자에 TRUE를 주면 공백 제거해 줌  

#### rvest 패키지 주요 함수 4 : 표에 있는 내용 일괄 수집
~~~
tbl <- html_table(
  x   = item,
  fill= FALSE
  )
~~~
* HTML의 'table' 태그는 웹 브라우저에서 표 형태로 데이터 출력  
* 테이블 안에 포함된 모든 데이터를 DF 형태로 수집하고자 할 때 사용  
* Windows 사용자의 경우 에러가 발생. 그 이유는 한글 인코딩 때문  
* 이러한 에러를 우회하는 방법으로 <b>로케일 변경</b>을 시도할 수 있음  

#### 한글 인코딩 관련 : 기본 패키지 + readr 패키지
* ` localeToCharset()` : 컴퓨터에 설정된 로케일의 문자 인코딩 방식을 확인    
* ` iconv(x='문자열', from = ‘UTF-8’ , to=‘ EUC-KR’) ` : : 인코딩 방식을 변경    
* ` readr::guess_encoding(file=‘파일명’)` : 컴퓨터에 저장된 파일 또는 URL의 문자 인코딩 방식을 확인  

#### 로케일 관련 : 기본 패키지
* ` Sys.getlocale()` : 현재 설정된 로케일 정보를 확인  
* ` Sys.setlocale( category = ‘LC_ALL’, locale = ‘localename’ )` : 인코딩 방식을 변경  
  * category 인자에는 ‘LC_COLLATE’, ‘LC_CTYPE’, ‘LC_MONETARY’, ‘LC_NUMERIC’, ‘LC_TIME’등   
개별 카테고리를 지정 할 수 있으나 편의상 ‘LC_ALL’로 지정  
* locale 인자에 지정할 locale name은 운영체제에 따라 서로 다름  
* Sys.setlocale() 함수 안에 아무런 인자를 지정하지 않으면 운영체제의 기본 값으로 설정  

### 퍼센트 인코딩 관련 : utltools 패키지
* 퍼센트 인코딩된 문자열은 urltools 패키지를 이용  
*  ` url_decode(urls=‘문자열A’) ` : 문자열A를 퍼센트 디코딩하여 사람이 읽을 수 있도록 함  
* ` url_decode(urls=‘문자열B’) `  : 문자열B를 퍼센트 인코딩하여 컴퓨터가 읽을 수 있도록 함  

### 텍스트 전처리 관련: stringr 패키지
* 문자 데이터를 다루는데 주요 함수를 담고 있음  
*  stringr은 파이프 연산자를 사용할 수 있음  
* stringr 패키지를 통해 다음과 같은 작업을 수행 할 수 있음
  * 패턴을 포함하고 있는지 확인 가능  
  * 패턴을 삭제(str_remove)하거나 교체(replace) 또는 추출(extract), 인덱스 자르기(sub)  
  * 문자열을 하나로 묶음(str_c) 또는 분리(str_split)  
  * 문자열의 양 옆에 있는 공백 제거(str_trim)  

* 각 함수 예제 확인  
  * ` string %>% str_detect(pattern=‘우리나라’) ` : 패턴 포함 여부 확인  
  * ` string %>% str_remove(pattern=‘’)` : 패턴 포함 한 번 삭제  
  * ` string %>% str_remove_all(pattern=‘’)` : 패턴 포함 한 번 삭제  
  * ` string %>% str_replace(pattern=‘우리나라’, replacement = '') ` : 패턴 포함 한번 교체  
  * ` string %>% str_extract(pattern='우') ` : 패턴 한 번 추출  
  * ` string %>% str_extract_all(pattern=‘우’) ` : 패턴 포함 모두 추출. list로 return  
  * ` string %>% str_sub(start=3,end=4) ` : 문자열을 인덱스로 자르기  
  * ` string %>% str_c(‘우리나라’, '만세', sep = '') ` : 문자열 묶음
  * ` string %>% str_split(pattern = '') ` : 문자열을 구분자로 분리   
  * ` string %>% str_trim()` : 문자열을 구분자로 분리  

## User-agent의 이해
* 인터넷 사용자가 웹 서버로 HTTP 요청을 하는 시점에 클라이언트 웹 브라우저는 HTTP 요청 메세지 중 헤더에 <b>사용자 에이전트를 함께 전송</b>  
* 사용자 에이전트는 애플리케이션 유형, 운영 체제, 웹 소프트웨어 등 클라이언트의 정보를 담은 문자열  
* 웹 서버는 이를 통해 클라이언트를 식별. 네이버 일부 서비스는 사용자 에이전트를 보고 4xx 를 return하는 경우가 있음  

#### User-agent 확인 방법
1. 크롬 개발자 도구의 Network 탭에서 Requestheaders를 확인  
2. 관련 웹 사이트 (WhoisHostingThis) 방문  
    https://www.whoishostingthis.com/tools/user-agent/  

#### R에서 User-agent 확인 방법
* HTTP 요청결과에서 list 객체 내 request 원소 확인  

#### R에서 User-agent setting 방법
~~~
res <- GET(
  url    = '네이버부동산URL',
  query  = list(querystrings),
  user_agent(agent = ua)
  )
~~~
