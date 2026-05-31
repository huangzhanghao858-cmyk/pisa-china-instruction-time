/*=============================================================================
  教学时长对学生学业成绩影响——中国PISA数据机制识别
  数据来源：
    pisa_stack.dta  — B&C复现数据（OECD 22国，2000-2018年）
    china_all.dta   — 自建中国面板（2009-2018年，4轮）

  ★ 首次运行前安装：
  ssc install reghdfe, replace  |  ssc install ftools,   replace
  ssc install estout,  replace  |  ssc install coefplot, replace
  cap ssc install binscatter, replace

  文件结构
  ─────────────────────────────────────────────────────────────────────
  PART 1   全局设置 & 路径
  PART 2   中国数据处理（各年原始文件）
  PART 3   合并 & 学校层面均值化
  PART 4   描述性统计（中国）
  ── OECD 分析（使用 pisa_stack.dta）────────────────────────────────
  PART 5  OECD 复现  
  PART 6  OECD 科目异质性  
  PART 7  东亚经济体比较
  ── 中国分析（使用 china_all.dta）──────────────────────────────────
  PART 8  中国基准回归  
  PART 9  NEW：非线性 / 阈值效应检验（中国）  
  PART 10 NEW：SES 异质性（中国）  
  PART 11 NEW：课外补习挤出机制（核心创新，中国）
  PART 11b NEW：省际异质性分析
  PART 12 NEW：科目异质性（分轮次验证）  
  PART 13 稳健性检验（中国全样本与机制稳健性）  
  PART 14 汇总输出（coefplot 总图）
  ─────────────────────────────────────────────────────────────────────
=============================================================================*/

clear all
set more off
cap log close


/*─────────────────────────────────────────────────────────────────────────────
  PART 1  全局设置 & 路径
─────────────────────────────────────────────────────────────────────────────*/

* !! 修改这里的路径，其余不需要改 !!
global ROOT  "D:\xuniCpan\统计调查\大作业"
global RAW09 "$ROOT\2009\INT_STQ09_DEC11.txt"
global RAW12 "$ROOT\2012\INT_STU12_DEC03.txt"
global RAW15 "$ROOT\2015\CY6_MS_CMB_STU_QQQ.sav"
global RAW18 "$ROOT\2018\CY07_MSU_STU_QQQ.sav"
global PISA  "$ROOT\pisa_stack.csv"
global OUT   "$ROOT\output1"

cap mkdir "$OUT"
log using "$ROOT\master_analysis.log", replace text


/*─────────────────────────────────────────────────────────────────────────────
  PART 2  数据处理（各年）
  ★ 相对原版更新：
─────────────────────────────────────────────────────────────────────────────*/

* ─── 2009───────────────────────────────────────────────────
clear
infix ///
    str3   CNT        1-3     ///
    str7   SCHOOLID   13-17   ///
    str5   StIDStd    18-22   ///
    int    ST04Q01    33-33   ///
    double LMINS      424-432 ///
    double MMINS      433-441 ///
    double SMINS      442-450 ///
    double PV1MATH    745-752 ///
    double PV2MATH    753-760 ///
    double PV3MATH    761-768 ///
    double PV4MATH    769-776 ///
    double PV5MATH    777-784 ///
    double PV1READ    785-792 ///
    double PV2READ    793-800 ///
    double PV3READ    801-808 ///
    double PV4READ    809-816 ///
    double PV5READ    817-824 ///
    double PV1SCIE    825-832 ///
    double PV2SCIE    833-840 ///
    double PV3SCIE    841-848 ///
    double PV4SCIE    849-856 ///
    double PV5SCIE    857-864 ///
    double ESCS       556-564 ///
    using "$RAW09"

keep if CNT == "QCN"
replace ESCS = . if ESCS >= 100 
foreach v of varlist LMINS MMINS SMINS {
    replace `v' = . if `v' >= 9998
}

gen ins_time_raw_math = MMINS / 60
gen ins_time_raw_read = LMINS / 60
gen ins_time_raw_scie = SMINS / 60

gen score_math = ((PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH) / 5 - 500) / 100
gen score_read = ((PV1READ + PV2READ + PV3READ + PV4READ + PV5READ) / 5 - 500) / 100
gen score_scie = ((PV1SCIE + PV2SCIE + PV3SCIE + PV4SCIE + PV5SCIE) / 5 - 500) / 100


* 省市标识（2009年仅上海）
gen province = "Shanghai"

gen uniq_stu_id_new = _n + 1000000
egen uniq_sch_id_new = group(CNT SCHOOLID)
replace uniq_sch_id_new = uniq_sch_id_new + 50000
rename ST04Q01 gender

keep uniq_stu_id_new uniq_sch_id_new gender ESCS province ///
     ins_time_raw_math ins_time_raw_read ins_time_raw_scie ///
     score_math score_read score_scie

reshape long ins_time_raw_ score_, i(uniq_stu_id_new) j(subject) string
rename ins_time_raw_ ins_time_raw
rename score_        lavy_zscore_pv1
rename uniq_stu_id_new uniq_stu_id
rename uniq_sch_id_new uniq_sch_id

gen sub  = 1 if subject == "read"
replace sub = 2 if subject == "math"
replace sub = 3 if subject == "scie"
gen wave = 2009
gen cnt  = "QCN"

* 2009年无课外补习变量
gen tutoring_raw = .

save "$ROOT\china_2009.dta", replace


* ─── 2012───────────────────────────────────────────────────
clear
infix ///
    str3   CNT        1-3      ///
    str7   SCHOOLID   25-31    ///
    str5   StIDStd    32-36    ///
    int    ST04Q01    47-47    ///
    int    ST69Q01    249-252  ///
    int    ST69Q02    253-256  ///
    int    ST69Q03    257-260  ///
    int    ST70Q01    261-264  ///
    int    ST70Q02    265-268  ///
    int    ST70Q03    269-272  ///
    double PV1MATH    1150-1158 ///
    double PV2MATH    1159-1167 ///
    double PV3MATH    1168-1176 ///
    double PV4MATH    1177-1185 ///
    double PV5MATH    1186-1194 ///
    double PV1READ    1510-1518 ///
    double PV2READ    1519-1527 ///
    double PV3READ    1528-1536 ///
    double PV4READ    1537-1545 ///
    double PV5READ    1546-1554 ///
    double PV1SCIE    1555-1563 ///
    double PV2SCIE    1564-1572 ///
    double PV3SCIE    1573-1581 ///
    double PV4SCIE    1582-1590 ///
    double PV5SCIE    1591-1599 ///
    double ESCS       650-657  ///
    using "$RAW12"
replace ESCS = . if ESCS >= 100 
keep if CNT == "QCN"

foreach v of varlist ST69Q01-ST70Q03 {
    replace `v' = . if `v' >= 9997
}

gen ins_time_raw_math = ST70Q02 * ST69Q02 / 60
gen ins_time_raw_read = ST70Q01 * ST69Q01 / 60
gen ins_time_raw_scie = ST70Q03 * ST69Q03 / 60

gen score_math = ((PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH) / 5 - 500) / 100
gen score_read = ((PV1READ + PV2READ + PV3READ + PV4READ + PV5READ) / 5 - 500) / 100
gen score_scie = ((PV1SCIE + PV2SCIE + PV3SCIE + PV4SCIE + PV5SCIE) / 5 - 500) / 100


gen province = "Shanghai"

gen uniq_stu_id_new = _n + 2000000
egen uniq_sch_id_new = group(CNT SCHOOLID)
replace uniq_sch_id_new = uniq_sch_id_new + 100000
rename ST04Q01 gender

keep uniq_stu_id_new uniq_sch_id_new gender ESCS province ///
     ins_time_raw_math ins_time_raw_read ins_time_raw_scie ///
     score_math score_read score_scie

reshape long ins_time_raw_ score_, i(uniq_stu_id_new) j(subject) string

rename ins_time_raw_ ins_time_raw
rename score_        lavy_zscore_pv1
rename uniq_stu_id_new uniq_stu_id
rename uniq_sch_id_new uniq_sch_id


gen sub  = 1 if subject == "read"
replace sub = 2 if subject == "math"
replace sub = 3 if subject == "scie"
gen wave = 2012
gen cnt  = "QCN"

gen tutoring_stu = .
gen tutoring_raw = .
label var tutoring_raw "每周校外学习总时长（2012年不可用）"

save "$ROOT\china_2012.dta", replace


* ─── 2015──────────────────────────────────────────────────────
import spss using "$RAW15", clear

keep if CNT == "QCH"

foreach v of varlist MMINS LMINS SMINS {
    replace `v' = . if `v' >= 99997
}

gen ins_time_raw_math = MMINS / 60
gen ins_time_raw_read = LMINS / 60
gen ins_time_raw_scie = SMINS / 60

gen score_math = ((PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH) / 5 - 500) / 100
gen score_read = ((PV1READ + PV2READ + PV3READ + PV4READ + PV5READ) / 5 - 500) / 100
gen score_scie = ((PV1SCIE + PV2SCIE + PV3SCIE + PV4SCIE + PV5SCIE) / 5 - 500) / 100

* ★2015年课外补习变量
* OUTHOURS：每周校外学习总时长
* HADDINST：本学年额外辅导总时长

replace OUTHOURS = . if OUTHOURS >= 997
gen tutoring_raw = OUTHOURS
label var tutoring_raw "每周校外学习总时长（OUTHOURS，小时/周；三科共享）"


cap gen haddinst_weekly = HADDINST / 35
label var haddinst_weekly "额外辅导周均时长（HADDINST/35）"


gen uniq_stu_id_new = _n + 3000000
egen uniq_sch_id_new = group(CNT CNTSCHID)
replace uniq_sch_id_new = uniq_sch_id_new + 200000
rename ST004D01T gender

keep uniq_stu_id_new uniq_sch_id_new gender ESCS ///
     ins_time_raw_math ins_time_raw_read ins_time_raw_scie ///
     tutoring_raw ///
     score_math score_read score_scie haddinst_weekly

reshape long ins_time_raw_ score_, ///
    i(uniq_stu_id_new uniq_sch_id_new gender ESCS haddinst_weekly tutoring_raw) ///
    j(subject) string

rename ins_time_raw_ ins_time_raw
rename score_        lavy_zscore_pv1
rename uniq_stu_id_new uniq_stu_id
rename uniq_sch_id_new uniq_sch_id

gen sub  = 1 if subject == "read"
replace sub = 2 if subject == "math"
replace sub = 3 if subject == "scie"
gen wave = 2015
gen cnt  = "QCH"

save "$ROOT\china_2015.dta", replace


* ─── 2018──────────────────────────────────────────────────────
import spss using "$RAW18", clear

keep if CNT == "QCI"

foreach v of varlist MMINS LMINS SMINS {
    replace `v' = . if `v' >= 99997
}

gen ins_time_raw_math = MMINS / 60
gen ins_time_raw_read = LMINS / 60
gen ins_time_raw_scie = SMINS / 60

gen score_math = ((PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH) / 5 - 500) / 100
gen score_read = ((PV1READ + PV2READ + PV3READ + PV4READ + PV5READ) / 5 - 500) / 100
gen score_scie = ((PV1SCIE + PV2SCIE + PV3SCIE + PV4SCIE + PV5SCIE) / 5 - 500) / 100

* ★ 2018年课外补习变量
gen tutoring_raw = .
label var tutoring_raw "每周校外学习总时长（2018年不可用）"

* 地区
gen province = ""
cap replace province = "Beijing"   if strpos(STRATUM, "BJ") > 0
cap replace province = "Shanghai"  if strpos(STRATUM, "SH") > 0
cap replace province = "Jiangsu"   if strpos(STRATUM, "JS") > 0
cap replace province = "Zhejiang"  if strpos(STRATUM, "ZJ") > 0

gen uniq_stu_id_new = _n + 4000000
egen uniq_sch_id_new = group(CNT CNTSCHID)
replace uniq_sch_id_new = uniq_sch_id_new + 300000
rename ST004D01T gender

keep uniq_stu_id_new uniq_sch_id_new gender ESCS province ///
     ins_time_raw_math ins_time_raw_read ins_time_raw_scie ///
     tutoring_raw ///
     score_math score_read score_scie

reshape long ins_time_raw_ score_, ///
    i(uniq_stu_id_new uniq_sch_id_new gender ESCS province tutoring_raw) ///
    j(subject) string

rename ins_time_raw_  ins_time_raw
rename score_         lavy_zscore_pv1
rename uniq_stu_id_new uniq_stu_id
rename uniq_sch_id_new uniq_sch_id

gen sub  = 1 if subject == "read"
replace sub = 2 if subject == "math"
replace sub = 3 if subject == "scie"
gen wave = 2018
gen cnt  = "QCI"

save "$ROOT\china_2018.dta", replace


/*─────────────────────────────────────────────────────────────────────────────
  PART 3  合并 & 关键变量构建
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_2009.dta", clear
append using "$ROOT\china_2012.dta"
append using "$ROOT\china_2015.dta"
append using "$ROOT\china_2018.dta"

* ─── 学校—科目—年份层面均值化教学时长 ───────────────────────
cap drop ins_time_sch
cap drop tutoring_sch
cap drop tutoring_stu
cap drop tut_available

bysort uniq_sch_id wave sub: egen ins_time_sch = mean(ins_time_raw)
label var ins_time_sch "每周教学时长（学校-科目均值，小时）"
label var ins_time_raw "每周教学时长（学生自报，小时）"

* ─── 课外补习：学校层面均值化 ───────────────────────────────────────────
bysort uniq_sch_id wave: egen tutoring_sch = mean(tutoring_raw)
label var tutoring_sch "每周校外学习学校均值（OUTHOURS；仅2015年有效）"

* ─── 学生层面补习总量 ────────────────────────────────────────────────────
bysort uniq_stu_id wave: egen tutoring_stu = mean(tutoring_raw)
label var tutoring_stu "每周校外学习总时长（OUTHOURS；仅2015年可用）"

* ─── 测量方式标识 ────────────────────────────────────────────────────────
gen tut_available = (wave == 2015)
label var tut_available "补习变量可用（仅2015年=1）"

* ─── HADDINST：额外辅导总时长（稳健性检验用）──────────────────
cap confirm variable haddinst_weekly
if _rc == 0 label var haddinst_weekly "额外辅导周均时长"

* ─── 标签 ─────────────────────────────────────────────────────────────────
label var lavy_zscore_pv1 "标准化成绩（5PV均值，z分数）"
label var ESCS            "家庭社会经济文化指数"
label var gender          "性别（1=女，2=男）"
label var province        "参与省市"

* ─── 检查样本 ──────────────────────────────────────────────────────────────
di "=== 各年份样本量 ==="
tab wave
tab wave, sum(ins_time_sch)
tab wave, sum(lavy_zscore_pv1)
tab wave, sum(tutoring_stu)
di "=== 省份 × 年份分布 ==="
tab province wave, miss
di "=== 2015年 tutoring_stu 描述统计 ==="
sum tutoring_stu if wave == 2015, detail

save "$ROOT\china_all.dta", replace


/*─────────────────────────────────────────────────────────────────────────────
  PART 4  描述性统计
  输出：tab_desc.rtf
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear
estimates clear

* 按年份的核心变量描述统计
estpost tabstat ins_time_sch lavy_zscore_pv1 tutoring_sch ESCS, ///
    by(wave) statistics(mean sd min max n) columns(statistics)
esttab using "$OUT\tab_desc.rtf", replace ///
    cells("mean(fmt(4)) sd(fmt(4)) min(fmt(4)) max(fmt(4)) count(fmt(0))") ///
    collabels("均值" "标准差" "最小值" "最大值" "观测数") ///
    title("描述性统计（按PISA年份）") noobs



/*─────────────────────────────────────────────────────────────────────────────
  PART 5  OECD 复现
  数据：pisa_stack.dta
  输出：5.1 tab_desc_oecd.rtf，5.2 table1_replication.rtf
─────────────────────────────────────────────────────────────────────────────*/

import delimited "$PISA", clear

save "$ROOT\pisa_stack.dta", replace

/*─────────────────────────────────────────────────────────────────────────────
  PART 5.1  描述性统计（OECD 国家样本）
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\pisa_stack.dta", clear
estimates clear

keep if oecd_lavy == 1

estpost tabstat ins_time_sch lavy_zscore_pv1, ///
    by(wave) statistics(mean sd min max n) columns(statistics)

esttab using "$OUT\tab_desc_oecd.rtf", replace ///
    cells("mean(fmt(4)) sd(fmt(4)) min(fmt(4)) max(fmt(4)) count(fmt(0))") ///
    collabels("均值" "标准差" "最小值" "最大值" "观测数") ///
    title("描述性统计（22个OECD国家样本，按PISA年份）") noobs

/*─────────────────────────────────────────────────────────────────────────────
  PART 5.2  OECD 复现回归分析
─────────────────────────────────────────────────────────────────────────────*/
	

foreach w in 2000 2006 2009 2012 2015 2018 {
    qui reghdfe lavy_zscore_pv1 ins_time_sch if wave == `w' & oecd_lavy == 1, ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store pisa`w'
    di "OECD PISA `w': b=" %8.4f _b[ins_time_sch] ///
       " SE=" %8.4f _se[ins_time_sch] " N=" e(N)
}

esttab pisa2000 pisa2006 pisa2009 pisa2012 pisa2015 pisa2018 ///
    using "$OUT\table1_replication.rtf", replace ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("PISA 2000" "PISA 2006" "PISA 2009" "PISA 2012" "PISA 2015" "PISA 2018") ///
    title("表1 每周教学时长对学生成绩的影响：22个OECD国家（复现B&C 2023）") ///
    note("注：所有回归控制学生固定效应和科目固定效应。括号内为学校层面聚类标准误。") ///
    stats(N, fmt(%9.0fc) labels("观测值"))


/*─────────────────────────────────────────────────────────────────────────────
  PART 6  OECD 科目异质性
  核心问题：数学/科学课时效应是否在OECD也高于语文？
  输出：tab_subj_oecd.rtf
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\pisa_stack.dta", clear

cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)

* ─── 6-1. OECD合并（全6轮）科目交互 ─────────────────────────────────────────
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie ///
    if oecd_lavy == 1, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store oecd_subj_all
estimates restore oecd_subj_all

qui lincom ins_time_sch + ins_X_math
estadd local eff_math = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
qui lincom ins_time_sch + ins_X_scie
estadd local eff_scie = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"

di _newline "=== OECD 合并样本科目异质性 ==="
di "语文（基准）：b=" %8.4f _b[ins_time_sch] " SE=" %8.4f _se[ins_time_sch]
lincom ins_time_sch + ins_X_math
di "数学合计效应：b=" %8.4f r(estimate) " SE=" %8.4f r(se)
lincom ins_time_sch + ins_X_scie
di "科学合计效应：b=" %8.4f r(estimate) " SE=" %8.4f r(se)

* ─── 6-2. OECD分轮次科目交互（稳健性）────────────────────────────────────
di _newline "=== OECD 分轮次科目异质性 ==="
foreach w in 2000 2006 2009 2012 2015 2018 {
    qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie ///
        if wave == `w' & oecd_lavy == 1, ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store oecd_subj`w'
    estimates restore oecd_subj`w'
    qui lincom ins_time_sch + ins_X_math
    local bm = r(estimate)
    estadd local eff_math = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
    qui lincom ins_time_sch + ins_X_scie
    estadd local eff_scie = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
    di "OECD PISA `w': 语文=" %8.4f _b[ins_time_sch] ///
       "  数学=" %8.4f `bm' "  科学=" %8.4f r(estimate)
}

* ─── 6-3. 输出（新增数学/科学合计效应行） ───────────────────────────────────
esttab oecd_subj_all ///
       oecd_subj2000 oecd_subj2006 oecd_subj2009 ///
       oecd_subj2012 oecd_subj2015 oecd_subj2018 ///
    using "$OUT\tab_subj_oecd.rtf", replace ///
    keep(ins_time_sch ins_X_math ins_X_scie) ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("合并" "2000" "2006" "2009" "2012" "2015" "2018") ///
    title("表A：OECD科目异质性——教学时长效应（基准=语文，22国）") ///
    note("注：ins_time_sch 为语文课时效应（基准）。" ///
         "数学/科学总效应为计算值，括号内为线性组合后的标准误。" ///
         "控制学生和科目固定效应，学校层面聚类标准误。") ///
    stats(eff_math eff_scie N, ///
          labels("数学合计效应 (语文+数学交互)" "科学合计效应 (语文+科学交互)" "观测值") ///
          fmt(string string %9.0fc))


/*─────────────────────────────────────────────────────────────────────────────
  PART 7  东亚经济体比较
  核心问题：日本/韩国课时效应是否也偏低？
  若是 → 叙事升级为"儒家教育体系共性"而非"中国特例"
  若否 → 中国在东亚内部亦为特例，需更具体机制解释
  数据：pisa_stack.dta  china_all.dta
  输出：tab_eastasia.rtf, tab_eastasia_wave.rtf fig_eastasia_compare.png
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\pisa_stack.dta", clear
cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)

* 标记东亚经济体
gen eastasia = inlist(cnt, "JPN", "KOR", "SGP", "HKG","MAC","TAP")
tab cnt if eastasia == 1, missing

* ─── 7-1. 各组合并估计 ───────────────────────────────────────────────────────
di _newline "=== 东亚经济体教学时长效应（合并6轮）==="

* [1] OECD全体
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie if oecd_lavy == 1, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store ea_oecd_all
estimates restore ea_oecd_all
qui lincom ins_time_sch + ins_X_math
estadd local eff_math = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
qui lincom ins_time_sch + ins_X_scie
estadd local eff_scie = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"

* [2] 非东亚OECD（剔除日韩后20国）
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie if oecd_lavy == 1 & eastasia == 0, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store ea_nonea
estimates restore ea_nonea
qui lincom ins_time_sch + ins_X_math
estadd local eff_math = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
qui lincom ins_time_sch + ins_X_scie
estadd local eff_scie = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"

* [3] 各东亚经济体循环估计
foreach c in JPN KOR HKG MAC TAP {
    cap qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie if cnt == "`c'", ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    if _rc == 0 {
        estimates store ea_`c'_all
        estimates restore ea_`c'_all
        
        di _newline "--- `c' 合并样本效应 ---"
        di "语文（基准）：b=" %8.4f _b[ins_time_sch] " SE=" %8.4f _se[ins_time_sch]
        
        qui lincom ins_time_sch + ins_X_math
        estadd local eff_math = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
        di "数学总效应：b=" %8.4f r(estimate) " SE=" %8.4f r(se)
        
        qui lincom ins_time_sch + ins_X_scie
        estadd local eff_scie = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
        di "科学总效应：b=" %8.4f r(estimate) " SE=" %8.4f r(se)
    }
}

* ─── 7-2. 中国大陆 ──────────────────
use "$ROOT\china_all.dta", clear

cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)

qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store ea_CHN_all
estimates restore ea_CHN_all

di _newline "--- 中国大陆（4轮合并） ---"
di "语文（基准）：b=" %8.4f _b[ins_time_sch] " SE=" %8.4f _se[ins_time_sch]

qui lincom ins_time_sch + ins_X_math
estadd local eff_math = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
di "数学总效应：b=" %8.4f r(estimate) " SE=" %8.4f r(se)

qui lincom ins_time_sch + ins_X_scie
estadd local eff_scie = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
di "科学总效应：b=" %8.4f r(estimate) " SE=" %8.4f r(se)


* ─── 7-3. 汇总对比表输出 ──────────────────────
esttab ea_oecd_all ea_nonea ea_JPN_all ea_KOR_all ea_CHN_all ea_HKG_all ea_MAC_all ea_TAP_all ///
    using "$OUT\tab_eastasia.rtf", replace ///
    keep(ins_time_sch ins_X_math ins_X_scie) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("OECD全体" "非东亚OECD" "日本" "韩国" "中国大陆" "中国香港" "中国澳门" "中国台湾") ///
    title("表3 东亚经济体教学时长效应与科目异质性对比") ///
    note("注：ins_time_sch 为语文（参照组）效应；数学/科学总效应为线性组合计算值，括号内为标准误。" ///
         "控制学生和科目固定效应，学校层面聚类标准误。") ///
    stats(eff_math eff_scie N, ///
          labels("数学合计效应 (语文+数学交互)" "科学合计效应 (语文+科学交互)" "观测值") ///
          fmt(string string %9.0fc))


* ─── 7-4. 东亚各经济体分轮次 ───────────
use "$ROOT\pisa_stack.dta", clear
cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)

di _newline "=== 东亚各经济体分轮次科目异质性估计 ==="

foreach c in JPN KOR HKG MAC TAP {
    foreach w in 2000 2006 2009 2012 2015 2018 {
        qui count if cnt == "`c'" & wave == `w'
        if r(N) > 100 { 
            qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie ///
                if cnt == "`c'" & wave == `w', ///
                absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
            estimates store ea_`c'`w'
            estimates restore ea_`c'`w'
            
            qui lincom ins_time_sch + ins_X_math
            local bm = r(estimate)
            estadd local eff_math = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
            
            qui lincom ins_time_sch + ins_X_scie
            estadd local eff_scie = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
            
            di "`c' `w': 语文=" %8.4f _b[ins_time_sch] " 数学=" %8.4f `bm' " 科学=" %8.4f r(estimate)
        }
        else {
            qui reg lavy_zscore_pv1 in 1/2
            estimates store ea_`c'`w'
            estimates restore ea_`c'`w'
            estadd local eff_math = ""
            estadd local eff_scie = ""
            di "【留白处理】`c' 在 `w' 年未参加，已在表格相应列和合计行中做留白处理。"
        }
    }
}

local first replace
foreach c in JPN KOR HKG MAC TAP {
    esttab ea_`c'2000 ea_`c'2006 ea_`c'2009 ea_`c'2012 ea_`c'2015 ea_`c'2018 ///
        using "$OUT\tab_eastasia_wave.rtf", `first' ///
        keep(ins_time_sch ins_X_math ins_X_scie) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
        mtitle("2000" "2006" "2009" "2012" "2015" "2018") ///
        title("`c'：各PISA轮次教学时长效应与科目异质性") ///
        stats(eff_math eff_scie N, ///
              labels("数学合计效应 (语文+数学交互)" "科学合计效应 (语文+科学交互)" "观测值") ///
              fmt(string string %9.0fc)) compress nogaps
    local first append
}

* ─── 7-5. 东亚对比图 ────────────────────────────────────────────────────────
* 绘制各经济体基准语文效应的对比
cap coefplot ///
    (ea_nonea,   label("非东亚OECD（20国）") mcolor(navy)       ciopts(lcolor(navy))) ///
    (ea_oecd_all, label("OECD全体（22国）")   mcolor(blue%60)   ciopts(lcolor(blue%60))) ///
    (ea_JPN_all,  label("日本")               mcolor(orange)    ciopts(lcolor(orange))) ///
    (ea_KOR_all,  label("韩国")               mcolor(red%80)    ciopts(lcolor(red%80))) ///
    (ea_CHN_all,  label("中国大陆")           mcolor(cranberry) ciopts(lcolor(cranberry))) ///
    (ea_HKG_all,  label("中国香港")           mcolor(purple%80) ciopts(lcolor(purple%80))) ///
    (ea_MAC_all,  label("中国澳门")           mcolor(dkgreen)   ciopts(lcolor(dkgreen))) ///
    (ea_TAP_all,  label("中国台湾")           mcolor(maroon)    ciopts(lcolor(maroon))), ///
    keep(ins_time_sch) vertical ///
    title("教学时长效应对比：东亚经济体 vs OECD (基准：语文)") ///
    ytitle("每增加1h课时的成绩变化（SD）") ///
    yline(0,      lp(dash)      lc(gray)) ///
    note("误差线为95%置信区间。控制学生与科目固定效应。") ///
    legend(rows(8)) graphregion(color(white)) bgcolor(white)

cap graph export "$OUT\fig_eastasia_compare.png", replace width(1400)

/*─────────────────────────────────────────────────────────────────────────────
  PART 8  中国基准回归
  数据：china_all.dta
  输出：table2_china.rtf
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear
estimates clear

* Panel A：各年份总体
foreach w in 2009 2012 2015 2018 {
    qui reghdfe lavy_zscore_pv1 ins_time_sch if wave == `w', ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store china_all`w'
}

* Panel B：女生
foreach w in 2009 2012 2015 2018 {
    qui reghdfe lavy_zscore_pv1 ins_time_sch if wave == `w' & gender == 1, ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store china_f`w'
}

* Panel C：男生
foreach w in 2009 2012 2015 2018 {
    qui reghdfe lavy_zscore_pv1 ins_time_sch if wave == `w' & gender == 2, ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store china_m`w'
}

esttab china_all2009 china_all2012 china_all2015 china_all2018 ///
    using "$OUT\table2_china.rtf", replace ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("2009" "2012" "2015" "2018") ///
    title("表2 教学时长对中国学生成绩影响的性别异质性") ///
    stats(N, fmt(%9.0fc) labels("观测值")) ///
    refcat(ins_time_sch "Panel A：全体学生", label("")) compress nogaps

esttab china_f2009 china_f2012 china_f2015 china_f2018 ///
    using "$OUT\table2_china.rtf", append ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    nonumbers nomtitles nonotes ///
    stats(N, fmt(%9.0fc) labels("观测值")) ///
    refcat(ins_time_sch "Panel B：女生样本", label("")) compress nogaps

esttab china_m2009 china_m2012 china_m2015 china_m2018 ///
    using "$OUT\table2_china.rtf", append ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    nonumbers nomtitles ///
    stats(N, fmt(%9.0fc) labels("观测值")) ///
    refcat(ins_time_sch "Panel C：男生样本", label("")) ///
    note("注：所有回归均控制学生固定效应和科目固定效应。括号内为学校层面聚类标准误。") compress nogaps

/*─────────────────────────────────────────────────────────────────────────────
  PART 9  NEW：非线性 / 阈值效应检验（中国）
  研究问题：中国课时偏高（~4.8h/周），是否处于边际效益递减区间？
    输出：tab_kink.rtf fig_binscatter_china_winsor.png
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear
estimates clear

* ─── 9-1. 分段线性（Kink 回归）─────────────────────────────────────────────
* 以3/4/5小时为候选阈值，检验超过阈值后斜率是否更低
di _newline "=== 分段线性回归（Kink） ==="
estimates clear

foreach t in 3 4 5 {
    cap drop above_`t'
    gen above_`t' = max(ins_time_sch - `t', 0)
    rename above_`t' slope_change
    qui reghdfe lavy_zscore_pv1 ins_time_sch slope_change, ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store kink`t'
    qui lincom ins_time_sch + slope_change
    estadd local high_slope = string(r(estimate), "%8.4f") + " (" + string(r(se), "%8.4f") + ")"
    rename slope_change above_`t'
}

esttab kink3 kink4 kink5 using "$OUT\tab_kink.rtf", replace ///
    keep(ins_time_sch slope_change) ///
    varlabels(ins_time_sch "低段基础斜率 (0-阈值)" ///
              slope_change "超过阈值后的斜率变化") ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("阈值=3h" "阈值=4h" "阈值=5h") ///
    title("表A1 分段线性回归：不同阈值的边际效应（中国样本）") ///
    note("注：低段斜率即为 ins_time_sch 的系数；斜率变化即为转折点后的增量。" ///
         "控制学生固定效应和科目固定效应，学校层面聚类标准误。") ///
    stats(high_slope N, labels("高段合计斜率" "观测值") fmt(string %9.0fc)) ///
    compress nogaps

* ─── 9-2. 二次项（倒U型检验）────────────────────────────────────────────────
gen ins_sq = ins_time_sch^2
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_sq, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store poly2

* 极值点（若β₁>0且β₂<0，则存在峰值）
di "极值点 = " %7.4f (-_b[ins_time_sch] / (2*_b[ins_sq])) " 小时/周"
nlcom -_b[ins_time_sch] / (2*_b[ins_sq])
drop ins_sq

esttab poly2 using "$OUT\tab_kink.rtf", append ///
    keep(ins_time_sch ins_sq) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("二次项模型") ///
    title("二次项回归：教学时长非线性效应")


* ─── 9-3. 散点图可视化（纯 binscatter 高密度学术版） ────────────────────────────
* 1. 提取控制学生和科目固定效应后的净残差
* 提取残差
qui reghdfe lavy_zscore_pv1, absorb(uniq_stu_id sub) resid
predict resid_score, resid
qui reghdfe ins_time_sch, absorb(uniq_stu_id sub) resid
predict resid_instr, resid

* 对自变量残差进行上下 1% 的缩尾处理，剔除两端极端值的长尾干扰
cap ssc install winsor2
winsor2 resid_instr, cuts(1 99) replace

* 重新绘制
binscatter resid_score resid_instr, ///
    nq(100) line(qfit) ///
    xtitle("教学时长（1%缩尾后残差）") ///
    ytitle("学业成绩（去固定效应残差）") ///
    title("教学时长与学业成绩的关系（稳健性检验）") ///
    note("注：对自变量进行了上下 1% 的缩尾处理，排除了极端尾部对二次拟合线的杠杆效应。") ///
    graphregion(color(white)) bgcolor(white)

cap graph export "$OUT\fig_binscatter_china_winsor.png", replace width(1200)

cap drop resid_score resid_instr

/*─────────────────────────────────────────────────────────────────────────────
  PART 9b NEW：科目间边际效应递减速率差异
  研究问题：三科课时效应的非线性结构是否存在异质性？
  识别策略：全样本合并回归 + 科目×二次项交互，absorb(uniq_stu_id sub)
            识别来自同一学生跨科目成绩差异，ins_time_sch在科目维度有变异
  插入位置：PART 9最后一行（cap drop resid_score resid_instr）之后，
            PART 10注释行之前
  输出：tab_quad_subj.rtf  fig_quad_subj.png
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear
estimates clear

* ─── 去除极端值（1%~99%截断）────────────────────────────────────────────────
qui sum ins_time_sch, detail
local p1  = r(p1)
local p99 = r(p99)
keep if ins_time_sch >= `p1' & ins_time_sch <= `p99'
di "截断后保留观测：" _N "（去除" 96540 - _N "条）"


* ─── 9b-1. 构造交互项 ───────────────────────────────────────────────────────
cap drop ins_time_sch2 ins_X_math ins_X_scie ins_sq_X_math ins_sq_X_scie

gen ins_time_sch2  = ins_time_sch^2
gen ins_X_math     = ins_time_sch  * (sub == 2)
gen ins_X_scie     = ins_time_sch  * (sub == 3)
gen ins_sq_X_math  = ins_time_sch2 * (sub == 2)
gen ins_sq_X_scie  = ins_time_sch2 * (sub == 3)

label var ins_time_sch2 "教学时长²"
label var ins_X_math    "教学时长 × 数学"
label var ins_X_scie    "教学时长 × 理科"
label var ins_sq_X_math "教学时长² × 数学"
label var ins_sq_X_scie "教学时长² × 理科"



* ─── 9b-2. 全样本合并回归 ───────────────────────────────────────────────────
qui reghdfe lavy_zscore_pv1 ///
    ins_time_sch  ins_time_sch2  ///
    ins_X_math    ins_sq_X_math  ///
    ins_X_scie    ins_sq_X_scie, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store quad_subj_all

* ─── 9b-3. 提取各科完整效应并计算拐点 ──────────────────────────────────────
di _newline "=== 各科线性项、二次项及拐点 ==="

* 语文（基准组）
local b1_read = _b[ins_time_sch]
local b2_read = _b[ins_time_sch2]
di "语文：β1=" %7.4f `b1_read' "  β2=" %7.4f `b2_read' ///
   "  拐点=" %7.4f (-`b1_read' / (2*`b2_read')) "h/周"

* 数学
qui lincom ins_time_sch  + ins_X_math
local b1_math = r(estimate)
qui lincom ins_time_sch2 + ins_sq_X_math
local b2_math = r(estimate)
di "数学：β1=" %7.4f `b1_math' "  β2=" %7.4f `b2_math' ///
   "  拐点=" %7.4f (-`b1_math' / (2*`b2_math')) "h/周"

* 理科
qui lincom ins_time_sch  + ins_X_scie
local b1_scie = r(estimate)
qui lincom ins_time_sch2 + ins_sq_X_scie
local b2_scie = r(estimate)
di "理科：β1=" %7.4f `b1_scie' "  β2=" %7.4f `b2_scie' ///
   "  拐点=" %7.4f (-`b1_scie' / (2*`b2_scie')) "h/周"

* ─── 9b-4. 联合检验：三科二次项系数是否相等 ─────────────────────────────────
di _newline "=== 联合检验：二次项系数科目间差异 ==="
di "语文 vs 数学（H0: β2相等）："
test ins_sq_X_math = 0
di "语文 vs 理科（H0: β2相等）："
test ins_sq_X_scie = 0
di "数学 vs 理科（H0: β2相等）："
test ins_sq_X_math = ins_sq_X_scie

* ─── 9b-5. 表格输出 ─────────────────────────────────────────────────────────
estimates restore quad_subj_all

local tp_read = -`b1_read' / (2*`b2_read')
local tp_math = -`b1_math' / (2*`b2_math')
local tp_scie = -`b1_scie' / (2*`b2_scie')

estadd local tp_str_read = string(`tp_read', "%7.4f")
estadd local tp_str_math = string(`tp_math', "%7.4f")
estadd local tp_str_scie = string(`tp_scie', "%7.4f")

esttab quad_subj_all using "$OUT\tab_quad_subj.rtf", replace ///
    keep(ins_time_sch ins_time_sch2 ins_X_math ins_sq_X_math ///
         ins_X_scie  ins_sq_X_scie) ///
    varlabels(ins_time_sch   "教学时长（语文基准）" ///
              ins_time_sch2  "教学时长²（语文基准）" ///
              ins_X_math     "教学时长 × 数学" ///
              ins_sq_X_math  "教学时长² × 数学" ///
              ins_X_scie     "教学时长 × 理科" ///
              ins_sq_X_scie  "教学时长² × 理科") ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) compress nogaps ///
    mtitle("合并回归（科目交互）") ///
    title("表Y 科目间边际效应递减速率差异") ///
    note("注：语文为基准科目。识别来自同一学生跨科目成绩差异。" ///
         "控制学生与科目固定效应，学校层面聚类标准误。" ///
         "拐点由各科线性组合系数计算：-β₁/(2β₂)。") ///
    stats(N, fmt(%9.0fc) labels("观测值"))

di _newline "=== 各科拐点汇总 ==="
di "语文拐点：" %7.4f `tp_read' " h/周"
di "数学拐点：" %7.4f `tp_math' " h/周"
di "理科拐点：" %7.4f `tp_scie' " h/周"

* ─── 9b-6. 可视化：三科效应曲线对比 ────────────────────────────────────────
qui sum ins_time_sch, detail
local xmin = r(p5)
local xmax = r(p95)

* 只在β2<0时画拐点竖线（仅数学符合）
local tp_math = -`b1_math' / (2*`b2_math')

twoway ///
    (function y = `b1_read'*x + `b2_read'*x^2, ///
        range(`xmin' `xmax') lcolor(navy) lwidth(medthick) lpattern(solid)) ///
    (function y = `b1_math'*x + `b2_math'*x^2, ///
        range(`xmin' `xmax') lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
    (function y = `b1_scie'*x + `b2_scie'*x^2, ///
        range(`xmin' `xmax') lcolor(dkgreen) lwidth(medthick) lpattern(shortdash)), ///
    yline(0, lp(dot) lc(gray%60)) ///
    xline(`tp_math', lp(dash) lc(cranberry%50) lwidth(thin)) ///
    xtitle("每周教学时长（学校均值，小时）", size(small)) ///
    ytitle("成绩变化（SD）", size(small)) ///
    title("三科课时效应曲线对比", size(medium)) ///
    note("注：红色虚竖线为数学估计拐点（`=string(`tp_math',"%4.1f")'h/周）。" ///
         "阅读和科学β₂方向不支持递减拐点解释。" ///
         "基于全样本科目交互二次项回归。控制学生与科目固定效应。") ///
    legend(order(1 "阅读" 2 "数学" 3 "科学") position(11) ring(0) cols(1) region(style(none)) size(small)) ///
    graphregion(color(white) fcolor(white) lcolor(white)) ///
    plotregion(color(white) fcolor(white) lcolor(white)) ///
    scheme(s1mono)

cap graph export "$OUT\fig_quad_subj.png", replace width(1200)

* ─── 清理 ────────────────────────────────────────────────────────────────────
cap drop ins_time_sch2 ins_X_math ins_X_scie ins_sq_X_math ins_sq_X_scie

di "=== PART 9b 科目非线性结构分析完成 ==="



/*─────────────────────────────────────────────────────────────────────────────
  PART 10 NEW：SES 异质性（中国）
  研究问题：低SES学生是否更依赖学校课时，课时效应是否随SES上升而下降？
  输出：tab_ses.rtf fig_ses_hetero.png
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear
estimates clear

* ─── 10-1. 分组回归（限定2015年） ──────────────────────────────────────────
cap drop escs_q
xtile escs_q = ESCS if wave == 2015, nq(4)

foreach q in 1 2 3 4 {
    qui reghdfe lavy_zscore_pv1 ins_time_sch if escs_q == `q' & wave == 2015, ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store escs_q`q'
}

* 输出分组 RTF 表格
esttab escs_q1 escs_q2 escs_q3 escs_q4 using "$OUT\tab_ses.rtf", replace ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) compress nogaps ///
    mtitle("低SES (Q1)" "中低 (Q2)" "中高 (Q3)" "高SES (Q4)") ///
    title("表A2 SES异质性：教学时长效应随家庭背景的变化（中国2015样本）") ///
    note("注：控制学生和科目固定效应，括号内为学校层面聚类标准误。") stats(N, fmt(%9.0fc) labels("观测值"))

* ─── 10-2. 连续交互项（限定2015年） ────────────────────────────────────────
cap drop ins_X_escs
gen ins_X_escs = ins_time_sch * ESCS

qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_escs if wave == 2015, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store ses_interact

* ─── 10-3. 可视化与清理 ───────────────────────────────────────────────────
coefplot (escs_q1, label("低SES (Q1)")) (escs_q2, label("中低SES (Q2)")) ///
         (escs_q3, label("中高SES (Q3)")) (escs_q4, label("高SES (Q4)")), ///
    keep(ins_time_sch) vertical yline(0, lp(dash) lc(gray)) legend(row(1) size(small)) ///
    title("中国大陆不同家庭背景（SES）学生的教学时长效应") ytitle("每增加1h课时的成绩变化（SD）") ///
    graphregion(color(white)) bgcolor(white)

cap graph export "$OUT\fig_ses_hetero.png", replace width(1200)
drop ins_X_escs escs_q

/*─────────────────────────────────────────────────────────────────────────────
  PART 11 NEW：课外补习挤出机制（核心创新，中国）
  数据说明：2015年（QCH）：OUTHOURS
  输出：mechanism_2015.rtf mechanism_2015.png
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear
estimates clear

* ─── 11-1. 构造 2015 年补习分组与中心化交互项 ────────────────────────────────
* 仅在变量有效的 2015 年样本中进行中位数切分与中心化
qui sum tutoring_stu if wave == 2015, detail
gen high_tut   = (tutoring_stu > r(p50)) if wave == 2015 & !missing(tutoring_stu)
gen tut_centered = tutoring_stu - r(mean) if wave == 2015

gen ins_X_tut = ins_time_sch * tut_centered

* ─── 11-2. 核心机制回归（2015年） ───────────────────────────────────────────
* (1) 基准效应
qui reghdfe lavy_zscore_pv1 ins_time_sch if wave == 2015, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store base_2015

* (2) 低补习组
qui reghdfe lavy_zscore_pv1 ins_time_sch if wave == 2015 & high_tut == 0, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store low_2015

* (3) 高补习组
qui reghdfe lavy_zscore_pv1 ins_time_sch if wave == 2015 & high_tut == 1, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store high_2015

* (4) 交互项回归
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_tut if wave == 2015, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store inter_2015

* ─── 11-3. 表格输出与可视化 ────────────────────────────────────────────────
esttab base_2015 low_2015 high_2015 inter_2015 using "$OUT\mechanism_2015.rtf", replace ///
    keep(ins_time_sch ins_X_tut) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) compress nogaps ///
    mtitle("2015基准" "低补习组" "高补习组" "交互模型") ///
    title("表A3 课外补习机制检验：学校课时对校外补习的挤出效应（2015样本）") ///
    note("注：补习强度以OUTHOURS（每周校外学习总时长）衡量，按2015年样本中位数划分高低组。所有模型均控制学生与科目固定效应。") ///
    stats(N, fmt(%9.0fc) labels("观测值"))

coefplot (low_2015, label("低补习组")) (high_2015, label("高补习组")), ///
    keep(ins_time_sch) vertical yline(0, lp(dash) lc(gray)) legend(row(1) size(small)) ///
    title("2015年中国大陆教学时长效应（按补习强度分组）") ytitle("成绩变化（SD）") ///
    graphregion(color(white)) bgcolor(white)

cap graph export "$OUT\mechanism_2015.png", replace width(1200)

* 安全清理
drop tut_centered ins_X_tut high_tut




/*─────────────────────────────────────────────────────────────────────────────
  PART 12 NEW：科目异质性（分轮次验证）
  输出：tab_subj_compare.rtf
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear

* ─── 12-1. 构造科目交互项与全样本合并回归 ─────────────────────────────────────
cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)

qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie, ///
    absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store china_subj_all

* ─── 12-2. 循环分轮次验证 ───────────────────────────────────────────────────
foreach w in 2009 2012 2015 2018 {
    qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie if wave == `w', ///
        absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store china_subj`w'
}

* ─── 12-3. 输出分轮次 RTF 表格 ────────────────────────────────────────────────
esttab china_subj_all china_subj2009 china_subj2012 china_subj2015 china_subj2018 ///
    using "$OUT\tab_subj_china.rtf", replace compress nogaps ///
    keep(ins_time_sch ins_X_math ins_X_scie) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("合并" "2009" "2012" "2015" "2018") title("表4 中国科目异质性分轮次验证") ///
    note("注：语文为基准组。控制学生和科目固定效应，括号内为学校层面聚类标准误。") stats(N, fmt(%9.0fc) labels("观测值"))

/*─────────────────────────────────────────────────────────────────────────────
  12.1 输出专用：OECD 与 中国 科目异质性回归与对比
─────────────────────────────────────────────────────────────────────────────*/

* 1. 重新跑中国样本 
use "$ROOT\china_all.dta", clear
cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie, absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store china_subj_all

* 2. 重新跑 OECD 样本
use "$ROOT\pisa_stack.dta", clear 

keep if oecd_lavy == 1
cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie, absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store oecd_subj_all

* 3. 强制输出表格
esttab oecd_subj_all china_subj_all using "$OUT\tab_subj_compare.rtf", replace ///
    compress nogaps b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("OECD（22国）" "中国（合并）") ///
    title("表5 科目异质性：OECD vs 中国") ///
    keep(ins_time_sch ins_X_math ins_X_scie) ///
    stats(N, fmt(%9.0fc) labels("观测值")) ///
    note("注：基准学科为语文。控制学生与科目固定效应，学校层面聚类标准误。")

di "--- 表5 已经生成：$OUT\tab_subj_compare.rtf ---"


/*─────────────────────────────────────────────────────────────────────────────
  PART 13 稳健性检验（中国全样本与机制稳健性）
  输出：tab_robust_zero.rtf tab_robust_subj.rtf tab_robust_haddinst.rtf fig_scatter_compare.png fig_mech_haddinst_scatter.png
─────────────────────────────────────────────────────────────────────────────*/
use "$ROOT\china_all.dta", clear
estimates clear

* ─── 13-1. 零效应稳健性：分年份个体自报值 ───────────────────────────────────
foreach w in 2009 2012 2015 2018 {
    qui reghdfe lavy_zscore_pv1 ins_time_raw if wave == `w', absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store raw`w'
}
esttab raw2009 raw2012 raw2015 raw2018 using "$OUT\tab_robust_zero.rtf", replace compress nogaps ///
    keep(ins_time_raw) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) mtitle("2009" "2012" "2015" "2018") ///
    title("表A 零效应稳健性：分年份个体自报值回归")

* ─── 13-2. 科目异质性稳健性（规格 1 & 2 & 3） ────────────────────────────────
* 规格1：基准（学校均值）
cap drop ins_X_math ins_X_scie
gen ins_X_math = ins_time_sch * (sub == 2)
gen ins_X_scie = ins_time_sch * (sub == 3)
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie, absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store subj_base

* 规格2：个体自报值
preserve
    drop ins_time_sch             
    rename ins_time_raw ins_time_sch 
    cap drop ins_X_math ins_X_scie
    gen ins_X_math = ins_time_sch * (sub == 2)
    gen ins_X_scie = ins_time_sch * (sub == 3)
    qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie, absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store subj_raw
restore

* 规格3：剔除极端值（±2SD 切割）
qui sum ins_time_sch, detail
qui reghdfe lavy_zscore_pv1 ins_time_sch ins_X_math ins_X_scie if inrange(ins_time_sch, r(mean)-2*r(sd), r(mean)+2*r(sd)), absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
estimates store subj_trim

* ─── 13-3. 输出科目异质性稳健性表 ──────────────────────────────────────────
esttab subj_base subj_raw subj_trim using "$OUT\tab_robust_subj.rtf", replace compress nogaps ///
    keep(ins_time_sch ins_X_math ins_X_scie) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("基准（学校均值）" "个体自报值" "剔除极端值") title("表B 科目异质性稳健性")

* ─── 13-4. 精准去残差双系统散点图 ──────────────────────────────────────────
qui reghdfe lavy_zscore_pv1, absorb(uniq_stu_id sub) resid(resid_score)
qui reghdfe ins_time_sch, absorb(uniq_stu_id sub) resid(resid_sch)
qui reghdfe ins_time_raw, absorb(uniq_stu_id sub) resid(resid_raw)

twoway (scatter resid_score resid_raw, mcolor(orange%15) msymbol(p)) ///
       (lfit resid_score resid_raw, lcolor(orange) lwidth(medthick) lpattern(dash)) ///
       (scatter resid_score resid_sch, mcolor(navy%25) msymbol(p)) ///
       (lfit resid_score resid_sch, lcolor(navy) lwidth(medthick)), ///
    xtitle("教学时长残差", size(small)) ytitle("成绩残差", size(small)) xsc(r(-6 6)) ysc(r(-3 3)) ///
    legend(order(3 "学校均值点" 4 "学校均值线" 1 "自报值点" 2 "自报值线") pos(11) ring(0) cols(1) size(small)) ///
    graphregion(color(white)) bgcolor(white) name(g_scat_comp, replace)
cap graph export "$OUT\fig_scatter_compare.png", replace width(1200)

* ─── 13-5. 机制替代稳健性：haddinst 替换验证（回归与表格导出版） ───────────
keep if wave == 2015
qui sum haddinst, detail
gen high_haddinst = (haddinst > r(p50)) if !missing(haddinst)

* 分组回归并存储结果
foreach g in 0 1 {
    * 1. 提取残差用于绘图
    qui reghdfe lavy_zscore_pv1 if high_haddinst == `g', absorb(uniq_stu_id sub) resid(rs_`g')
    qui reghdfe ins_time_sch if high_haddinst == `g', absorb(uniq_stu_id sub) resid(xt_`g')
    
    * 2. 跑回归并存储模型，供后面导出表格
    qui reghdfe lavy_zscore_pv1 ins_time_sch if high_haddinst == `g', absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
    estimates store reg_group_`g'
    
    * 3. 提取系数供图例使用
    local b`g': display %6.4f _b[ins_time_sch]
    local se`g': display %5.4f _se[ins_time_sch]
}

* --- 表格输出 ---
esttab reg_group_0 reg_group_1 using "$OUT\tab_robust_haddinst.rtf", replace compress nogaps ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("低额外辅导组" "高额外辅导组") ///
    title("表C 机制检验：额外辅导强度的异质性回归") ///
    stats(N, fmt(%9.0fc) labels("观测值"))

twoway (scatter rs_0 xt_0, mcolor(navy%12) msymbol(p)) (lfit rs_0 xt_0, lcolor(navy) lwidth(thick)) ///
       (scatter rs_1 xt_1, mcolor(cranberry%12) msymbol(p)) (lfit rs_1 xt_1, lcolor(cranberry) lwidth(thick) lpattern(dash)), ///
    xtitle("教学时长残差") ytitle("成绩残差") title("机制检验：不同额外辅导强度的效应对比") ///
    xsc(r(-3 3)) ysc(r(-3 3)) xlabel(-3(1)3) ylabel(-3(1)3) ///
    legend(order(2 "低额外辅导组 (β = `b0')" 4 "高额外辅导组 (β = `b1')") pos(11) ring(0) cols(1) size(small) region(lstyle(none))) ///
    graphregion(color(white)) bgcolor(white) name(g_mech_combine, replace)

cap graph export "$OUT\fig_mech_haddinst_scatter.png", replace width(1200)

* ─── 13-6. 终极内存大扫除 ────────────────────────────────────────────────────
cap graph drop _all
cap drop resid_* rs_* xt_* high_haddinst

/*─────────────────────────────────────────────────────────────────────────────
  PART 14 汇总输出（coefplot 总图）
  输出：fig_coef_summary.png
─────────────────────────────────────────────────────────────────────────────*/
* 重新整合模型列表（这里以你的核心稳健性结果为例）
coefplot (raw2009, label("2009")) (raw2012, label("2012")) ///
         (raw2015, label("2015")) (raw2018, label("2018")), ///
    keep(ins_time_raw) /// <-- 确保这里是回归中实际存在的变量名
    vertical yline(0, lp(dash) lc(red)) ///
    ciopts(lwidth(1.2) lcolor(navy%50)) /// 设置置信区间样式
    msymbol(O) mcolor(navy) mfcolor(white) /// 设置点样式
    title("教学时长效应：分年份回归汇总", size(medium)) ///
    ytitle("回归系数（标准化成绩）") ///
    graphregion(color(white)) bgcolor(white) ///
    plotregion(margin(medium))

* 导出汇总图
cap graph export "$OUT\fig_coef_summary.png", replace width(2000)

* --- 结果导向说明 ---
di _newline "====== 全部工作已优雅收尾 ======"
di "祝贺！所有实证过程已自动流水线化。"
di "输出结果已全部就绪，请前往 $OUT 查收 RTF 表格与 PNG 图表。"
log close
