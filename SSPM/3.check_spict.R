#########################################################
#########################################################
#
# 令和４年度資源管理研修会
#   SPiCTを用いた状態空間プロダクションモデルによる
#   資源解析の演習
#	3.	SPiCT解析の結果の検討
#	
#   Author: Kohei Hamabe & Akira Hirao
#
#########################################################
#########################################################

# 必要なパッケージの呼び出し----
library(tidyverse)
library(spict)


#=================================================
## "1.run_spict.R"または"2.uncertainty.R"が実行済みで
## SPiCT解析の結果オブジェクトresが得られていることが
## 本スクリプトの実行の前提条件です

#res <- fit.spict(inp)



#########################################################
### 1. 解析結果の確認

# 結果を要約する
summary(res)

# 推定された初期資源量の割合がデフォルトでは出ないので，出す
get.par("logbkfrac", res, exp = TRUE) #オプションexp=TRUEによって、log推定値を非対数に戻す

#入力データの初期値を確認する：入力データが正しく設定されているかを事後のチェックをしておきましょう
res$inp$ini  # res$inp (spict解析に用いた入力データのオブジェクト)

##------------------------------------------
## 推定が上手くいっているかの確認事項・その１
##
## その１−１: 収束しているかどうかを判定
res$opt$convergence  #これが0だったら，収束しているのでOK; もし1だったら、収束していないので結果は信頼できない
##
##
## その１−２: 推定パラメータの分散が有限かどうかを判定
all(is.finite(res$sd))  # TRUEだったらパラメータの分散が全て有限であるということでOK
##
##
## その１−３: B/BmsyやF/Fmsyの信用区間が一桁以上に広がっていないかどうかを確認
calc.om(res) #戻り値のmagnitudeが1 以下ならばOK
##
##
## その１−４: 初期値によってパラメータの推定値が変わらないかどうかを確認
## check.ini(res)で初期値を変えたときの影響をみることができる．
## そしてfit<-check.ini(res)としてfit$check.ini$resmatとすると10回分の推定パラの値の一覧が出てくる．
options(max.print = 1e+05)
fit <- check.ini(res, ntrials = 10)  #ntrials = 20に増やしてもよい？
##
fit$check.ini$inimat  #trial毎に与えた初期値を確認しておく
##
fit$check.ini$resmat  #初期値を変えたtrialによって推定された値。初期値によってはNAとなる場合も。。。
##
## 初期値によって推定されるパラメータの値が変わるので，どちらが尤度が高いのか比較する場合
## 計算したいtrialnoを指定して尤度を計算する
##
## trial<-'Trial 22'#ここで自分の選んだtrial noを指定
## b<-fit$check.ini$inimat[trial,,drop=F] rownames(b)<-NULL
##
## inp$ini$logn<-b[,'logn'] inp$ini$logK<-b[,'logK'] inp$ini$logm<-b[,'logm']
## inp$ini$logq1<- b[,'logq1'] inp$ini$logq2<- b[,'logq2'] inp$ini$logsdb<-
## b[,'logsdb'] inp$ini$logsdf<- b[,'logsdf'] inp$ini$logsdi1<- b[,'logsdi1']
## inp$ini$logsdi2<- b[,'logsdi2'] inp$ini$logsdc<- b[,'logsdc']
## res2<-fit.spict(inp) res2$opt$convergence #収束しているか確認
## res2$opt$objective #初期値を変えた，trial*番の最尤推定値 res$opt$objective
## もともの最尤推定値
##-------------------------------------------



#########################################################
#### ２．結果のプロット

plot(res) #全体的な結果のプロット

##-------------------------------------------
## 推定が上手くいっているかの確認事項・その２
## 余剰生産曲線の形が現実的であるかどうか
calc.bmsyk(res)　
##この値が0.1—0.9の範囲外にある場合は、余剰生産曲線の形が偏っている
##-------------------------------------------




#########################################################
#### ３．推定パラメーターの事前分布と事後分布のプロット

plotspict.priors(res)  #事前分布と事後分布




#########################################################
#### ４．残差診断（バイアス、自己相関、正規性の診断）

res_resi <- calc.osa.resid(res)
plotspict.diagnostic(res_resi)

##------------------------------------------- 
##　推定が上手くいっているか確認事項・その３
## p値が0.05より大きい(有意に差がない．有意に差があると，
## 図の上のp値の文字が赤色になる．緑色ならOK)
##-------------------------------------------




#########################################################
####　５．レトロスペクティブ解析

res_retro <- retro(res, nretroyear = 5)　#レトロスペクティブ解析を実行
plotspict.retro(res_retro)  #レトロ解析プロット

plotspict.retro.fixed(res_retro)  #推定パラメータに関するレトロプロット

mohns_rho(res_retro, what = c("FFmsy", "BBmsy"))  #モーンズローの値を表示

##------------------------------------------- 
##　推定が上手くいっているか確認事項・その4
## レトロ解析パターンに一貫性があるかどうか：
## チェックポイント１：F/FmsyやB/Bmsyが連続に一貫して過小評価あるいは過大評価されていないか
## チェックポイント2：ベースケースの信用区間内にあるかどうか
#-------------------------------------------



#########################################################
####　６．資源変動の要因分解プロット

#frapmr::plot_barbiomass(res)　
# plot_barbiomassはFRAが開発しているパッケージfrapmrの自作関数です。
# frapmrのインストール方法はコチラ：https://github.com/ichimomo/frapmr

##------------------------------------------- 
##　推定が上手くいっているか確認事項・その5
## 図の灰色は資源量の推定値を示し、赤、緑、青の矢印がそれぞれの資源量の変動に対する
## 余剰生産、漁獲、プロセス誤差の影響の大きさを示す
## チェックポイント：資源量の変動の大部分がプロセス誤差で説明されている場合はよい推定ではない
#-------------------------------------------
