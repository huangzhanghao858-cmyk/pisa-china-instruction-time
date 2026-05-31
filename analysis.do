/*=============================================================================
  修改说明（相对原版 master_analysis_full1.do）
  1. 成绩变量：改用5个PV均值，不再只用PV1（四年统一）
  2. tutoring_raw：2015年不做三等分，直接用OUTHOURS原值
     2009/2012/2018统一生成缺失占位
  3. PART 3：tutoring_sch 去掉sub维度；tutoring_stu 去掉*3
  4. 新增 PART 11b：省际异质性分析
=============================================================================*/


/*─────────────────────────────────────────────────────────────────────────────
  PART 2  数据处理（各年）
─────────────────────────────────────────────────────────────────────────────*/

* ─── 2009 ───────────────────────────────────────────────────────────────────
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

* ── 成绩：5个PV均值后标准化 ──
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

gen tutoring_raw = .
label var tutoring_raw "每周校外学习总时长（2009年不可用）"

save "$ROOT\china_2009.dta", replace


* ─── 2012 ───────────────────────────────────────────────────────────────────
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

* ── 成绩：5个PV均值后标准化 ──
gen score_math = ((PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH) / 5 - 500) / 100
gen score_read = ((PV1READ + PV2READ + PV3READ + PV4READ + PV5READ) / 5 - 500) / 100
gen score_scie = ((PV1SCIE + PV2SCIE + PV3SCIE + PV4SCIE + PV5SCIE) / 5 - 500) / 100

* 省市标识（2012年仅上海）
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

gen tutoring_raw = .
label var tutoring_raw "每周校外学习总时长（2012年不可用）"

save "$ROOT\china_2012.dta", replace


* ─── 2015 ───────────────────────────────────────────────────────────────────
import spss using "$RAW15", clear

keep if CNT == "QCH"

foreach v of varlist MMINS LMINS SMINS {
    replace `v' = . if `v' >= 99997
}

gen ins_time_raw_math = MMINS / 60
gen ins_time_raw_read = LMINS / 60
gen ins_time_raw_scie = SMINS / 60

* ── 成绩：5个PV均值后标准化 ──
gen score_math = ((PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH) / 5 - 500) / 100
gen score_read = ((PV1READ + PV2READ + PV3READ + PV4READ + PV5READ) / 5 - 500) / 100
gen score_scie = ((PV1SCIE + PV2SCIE + PV3SCIE + PV4SCIE + PV5SCIE) / 5 - 500) / 100

* ── 补习变量：直接用OUTHOURS原值，不拆科 ──
replace OUTHOURS = . if OUTHOURS >= 997
gen tutoring_raw = OUTHOURS
label var tutoring_raw "每周校外学习总时长（OUTHOURS，小时/周；三科共享）"

* HADDINST：额外辅导总时长（稳健性检验用）
cap gen haddinst_weekly = HADDINST / 35
label var haddinst_weekly "额外辅导周均时长（HADDINST/35）"

* 地区
gen province = ""
cap replace province = "Beijing"   if strpos(STRATUM, "BJ") > 0
cap replace province = "Shanghai"  if strpos(STRATUM, "SH") > 0
cap replace province = "Jiangsu"   if strpos(STRATUM, "JS") > 0
cap replace province = "Guangdong" if strpos(STRATUM, "GD") > 0

di "=== 2015年省份分布确认 ==="
tab province, miss

gen uniq_stu_id_new = _n + 3000000
egen uniq_sch_id_new = group(CNT CNTSCHID)
replace uniq_sch_id_new = uniq_sch_id_new + 200000
rename ST004D01T gender

keep uniq_stu_id_new uniq_sch_id_new gender ESCS province ///
     ins_time_raw_math ins_time_raw_read ins_time_raw_scie ///
     tutoring_raw ///
     score_math score_read score_scie haddinst_weekly

* tutoring_raw 放入 i() 作为学生层常数随科目行复制（三科值相同）
reshape long ins_time_raw_ score_, ///
    i(uniq_stu_id_new uniq_sch_id_new gender ESCS province haddinst_weekly tutoring_raw) ///
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


* ─── 2018 ───────────────────────────────────────────────────────────────────
import spss using "$RAW18", clear

keep if CNT == "QCI"

foreach v of varlist MMINS LMINS SMINS {
    replace `v' = . if `v' >= 99997
}

gen ins_time_raw_math = MMINS / 60
gen ins_time_raw_read = LMINS / 60
gen ins_time_raw_scie = SMINS / 60

* ── 成绩：5个PV均值后标准化 ──
gen score_math = ((PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH) / 5 - 500) / 100
gen score_read = ((PV1READ + PV2READ + PV3READ + PV4READ + PV5READ) / 5 - 500) / 100
gen score_scie = ((PV1SCIE + PV2SCIE + PV3SCIE + PV4SCIE + PV5SCIE) / 5 - 500) / 100

* 2018年无OUTHOURS，生成缺失占位
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

* ─── 教学时长：学校-科目-年份均值 ───────────────────────────────────────────
cap drop ins_time_sch
cap drop tutoring_sch
cap drop tutoring_stu
cap drop tut_available

bysort uniq_sch_id wave sub: egen ins_time_sch = mean(ins_time_raw)
label var ins_time_sch "每周教学时长（学校-科目均值，小时）"
label var ins_time_raw "每周教学时长（学生自报，小时）"

* ─── 补习：学校-年份均值（不含sub维度，因补习不拆科）──────────────────────
bysort uniq_sch_id wave: egen tutoring_sch = mean(tutoring_raw)
label var tutoring_sch "每周校外学习学校均值（OUTHOURS；仅2015年有效）"

* ─── 学生补习总量（直接均值，无需*3）────────────────────────────────────────
* tutoring_raw本身即OUTHOURS原值，三科行均值 = OUTHOURS
bysort uniq_stu_id wave: egen tutoring_stu = mean(tutoring_raw)
label var tutoring_stu "每周校外学习总时长（OUTHOURS；仅2015年可用）"

* ─── 测量方式标识 ────────────────────────────────────────────────────────────
gen tut_available = (wave == 2015)
label var tut_available "补习变量可用（仅2015年=1）"

* ─── HADDINST ────────────────────────────────────────────────────────────────
cap confirm variable haddinst_weekly
if _rc == 0 label var haddinst_weekly "额外辅导周均时长"

* ─── 标签 ───────────────────────────────────────────────────────────────────
label var lavy_zscore_pv1 "标准化成绩（5PV均值，z分数）"
label var ESCS            "家庭社会经济文化指数"
label var gender          "性别（1=女，2=男）"
label var province        "参与省市"

* ─── 检查 ────────────────────────────────────────────────────────────────────
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
  PART 11b NEW：省际异质性分析
  输出：tab_province_2015.rtf  tab_province_2018.rtf  fig_province_coef.png
─────────────────────────────────────────────────────────────────────────────*/

use "$ROOT\china_all.dta", clear
estimates clear

di "=== 省份实际取值确认 ==="
tab province wave, miss

* ─── 11b-1. 2015年分省回归（上海/北京/江苏/广东）───────────────────────────
local provs_2015 `" "Shanghai" "Beijing" "Jiangsu" "Guangdong" "'
local names_2015  " sh bj js gd "

local n15 : word count `names_2015'
forvalues i = 1/`n15' {
    local p  : word `i' of `provs_2015'
    local pn : word `i' of `names_2015'

    qui count if province == "`p'" & wave == 2015
    di "2015 · `p'：N = " r(N)

    if r(N) > 100 {
        qui reghdfe lavy_zscore_pv1 ins_time_sch ///
            if province == "`p'" & wave == 2015, ///
            absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
        estimates store p15_`pn'
        di "  ✓ p15_`pn' 已存储  b=" %6.4f _b[ins_time_sch]
    }
    else {
        di "  ⚠ `p' 2015年样本不足，跳过"
    }
}

cap esttab p15_sh p15_bj p15_js p15_gd ///
    using "$OUT\tab_province_2015.rtf", replace ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) compress nogaps ///
    mtitle("上海" "北京" "江苏" "广东") ///
    title("表X1 省际异质性：教学时长效应分省估计（2015年）") ///
    note("注：成绩为5个PV均值标准化。控制学生与科目固定效应，学校层面聚类标准误。") ///
    stats(N, fmt(%9.0fc) labels("观测值"))

* ─── 11b-2. 2018年分省回归（上海/北京/江苏/浙江）──────────────────────────
local provs_2018 `" "Shanghai" "Beijing" "Jiangsu" "Zhejiang" "'
local names_2018  " sh bj js zj "

local n18 : word count `names_2018'
forvalues i = 1/`n18' {
    local p  : word `i' of `provs_2018'
    local pn : word `i' of `names_2018'

    qui count if province == "`p'" & wave == 2018
    di "2018 · `p'：N = " r(N)

    if r(N) > 100 {
        qui reghdfe lavy_zscore_pv1 ins_time_sch ///
            if province == "`p'" & wave == 2018, ///
            absorb(uniq_stu_id sub) vce(cluster uniq_sch_id)
        estimates store p18_`pn'
        di "  ✓ p18_`pn' 已存储  b=" %6.4f _b[ins_time_sch]
    }
    else {
        di "  ⚠ `p' 2018年样本不足，跳过"
    }
}

cap esttab p18_sh p18_bj p18_js p18_zj ///
    using "$OUT\tab_province_2018.rtf", replace ///
    keep(ins_time_sch) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) compress nogaps ///
    mtitle("上海" "北京" "江苏" "浙江") ///
    title("表X2 省际异质性：教学时长效应分省估计（2018年）") ///
    note("注：成绩为5个PV均值标准化。控制学生与科目固定效应，学校层面聚类标准误。") ///
    stats(N, fmt(%9.0fc) labels("观测值"))

* ─── 11b-3. coefplot 省际对比图（2015年）──────────────────────────────────
cap coefplot ///
    (p15_sh, label("上海")  mcolor(navy)      ciopts(lcolor(navy))) ///
    (p15_bj, label("北京")  mcolor(cranberry) ciopts(lcolor(cranberry))) ///
    (p15_js, label("江苏")  mcolor(dkgreen)   ciopts(lcolor(dkgreen))) ///
    (p15_gd, label("广东")  mcolor(orange)    ciopts(lcolor(orange))), ///
    keep(ins_time_sch) vertical ///
    yline(0, lp(dash) lc(gray)) ///
    title("省际异质性：教学时长效应分省比较（2015年）", size(medium)) ///
    ytitle("每增加1h课时的成绩变化（SD）") ///
    note("成绩为5PV均值。误差线为95%置信区间。控制学生与科目固定效应。") ///
    legend(rows(1) size(small)) ///
    graphregion(color(white)) bgcolor(white)

cap graph export "$OUT\fig_province_coef.png", replace width(1200)

di "=== PART 11b 省际异质性完成 ==="
