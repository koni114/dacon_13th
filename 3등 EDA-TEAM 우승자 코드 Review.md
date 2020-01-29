## 3등 EDA-TEAM 우승자 코드 Review
### 개요
* 기존 우승자들의 소스 코드 리뷰 진행
* Idea 위주로 정리
* 내가 놓친 부분은 어떤 부분일까?

#### Feature Engineering
* 주어진 Data의 기본 통계량 값을 가지고 FE 진행
  * 배차 간격
  * 주중에 정기적으로 타는 사람들
  * 12시 이후 정류장 하차 인원
  * 아침, 오전(3시간 간격) 각 집단 별 탑승 인원
  *  아침, 오전(3시간 간격) 각 집단 별 하차 인원
* K-Means 를 통한 군집 변수 생성
* 기상 데이터
  * 12시 전에 수집된 강수량
  * 전날 강수량
  * 12시 전에 수집된 운집량
* Google-Map을 통한 정류장의 주소 정보
  * 주소 별 거주자 수
* Station 정보
  * Station 별 평균 탑승 시간
  * 정류장별 일평균 승차, 하차 승객의 차이
* Airport(**) : 공항 승객 정보를 외부 데이터로 사용
  * 일일 예상 승객
  * 일일 도착 승객
  * 제주 공항 운집 데이터
* 제주도 거주자 수

#### Encoding
* Label encoding
* frequency encoding

#### Modeling
* CatBoost
  * learning_rate : 0.05
  * eval_metric : RMSE
  * loss_function : RMSE
  * random_seed : 42
  * metric_period : 500
  * od_wait : 500
  * task_type : GPU
  * l2_leaf_reg : 3
  * depth : 8
* LGBM
  * random_state : 1993
  * learning_rate : 0.05
  * subsample : 0.7
  * tree_learner : 'serial'
  * colsample_bytree : 0.78
  * early_stopping_rounds : 50
  * subsample_freq : 1
  * reg_lambda : 7
  * reg_alpha : 5
  * num_leaves : 96
#### Ansemble : Stacking
* cat_port, cat, lgbm, lgbm_port 4개의 모델 결과 값 평균 수행
