

/*********Code for making UPC code unique*********/

proc import datafile="D:\Coll\Spring 17\Mkt Pred\Murthy\project\hhclean\prod_hhclean" out=ProductDetails dbms=xls replace;
getnames=yes;
run;

Data productdetails;
set productdetails;
UPC_Code=UPC;
run;

proc sort data=productdetails;
by UPC_Code;
run;

proc sort data=a.salesy;
by UPC_Code;
run;

data a.Prod_Salesy;
merge productdetails a.salesy;
by UPC_Code;
run;
/*************UPC CODE ENDS***************FINAL TABLE = PROD_SALESy*/

PROC CONTENTS data=a.prod_salesy; run;

data a.prod_salesy;
set a.prod_salesy;
Company = L4;
Brand = L5;
PRICE = (DOLLARS/UNITS)/Vol_EQ;
size=scan(L9,-1," ");
Run;

PROC CONTENTS data=a.prod_salesy out=content; run;

/******** DELETE MISSING VALUES *************/

data a.prod_salesy5;
set a.prod_salesy;
IF PR='.' then DELETE;
if form='LIQUID' then form_l_d= 1; else form_l_d= 0;
if form='SPRAY' then form_s_d= 1; else form_s_d= 0;
DROP ADDITIVES CONCENTRATION_LEVEL l1 l2 l3 l4 l5 l9 level upc _STUBSPEC_1856RC vend_n
vend1 vend TYPE_OF_CLEANER_DISF sy sy1 sy_n STRENGTH ge ge1 ge_n item item1 item_n
product_type;
size_n=(compress(size,"OZ"))*1.0;
drop size;
run;

proc rank data=a.prod_salesy5 out=a.prod_salesy5 groups=3; 
var size_n;
ranks size;
run;

data a.prod_salesy5;
set a.prod_salesy5;
if size=0 then size_l_d=1; else size_l_d=0;
if size=2 then size_h_d=1; else size_h_d=0;
drop size;
run;

PROC MEANS DATA=a.prod_salesy5 nmiss;run;


/************Top Sales Brand*************/

proc sql;
create table Top_brand as
select  Brand, sum(units)as Units, sum(dollars) as Dollars
from a.Prod_Salesy5
group by Brand
Order by Dollars DESC;
quit;

/************Market Share *************/

proc sql;
create table weekly_Total_Dollars as
select week,  sum(dollars) as sum_dollars
from a.Prod_Salesy5
group by week
Order by week;
quit;

proc sql;
create table PINE_SOL  as
select week,  sum(dollars) as sum_PINE_SOL, avg(price) as avg_PINE_SOL
from a.Prod_Salesy5
where brand = 'PINE SOL'
group by week
Order by week;
quit;

proc sql;
create table LYSOL  as
select week, sum(dollars) as sum_LYSOL,  avg(price) as avg_LYSOL
from a.Prod_Salesy5
where brand = 'LYSOL'
group by week
Order by week;
quit;

proc sql;
create table private  as
select week, sum(dollars) as sum_private,  avg(price) as avg_private
from a.Prod_Salesy5
where brand = 'PRIVATE LABEL'
group by week
Order by week;
quit;

proc sql;
create table FORMULA_409  as
select week, sum(dollars) as sum_FORMULA_409,  avg(price) as avg_FORMULA_409
from a.Prod_Salesy5
where brand = 'FORMULA 409'
group by week
Order by week;
quit;

proc sql;
create table CLOROX_CLEAN_UP  as
select week, sum(dollars) as sum_ccu,  avg(price) as avg_ccu
from a.Prod_Salesy5
where brand = 'CLOROX CLEAN UP'
group by week
Order by week;
quit;

proc sql;
create table FANTASTIK  as
select week, sum(dollars) as sum_FANTASTIK,  avg(price) as avg_FANTASTIK
from a.Prod_Salesy5
where brand = 'FANTASTIK'
group by week
Order by week;
quit;
/*clorox_clean_up fantastik;*/
data  a.MS;
merge private weekly_Total_Dollars pine_sol lysol formula_409 ;
MS = sum_PINE_SOL / sum_dollars;
MS1 = sum_LYSOL / sum_dollars;
MS3 = sum_private / sum_dollars;
MS2 = sum_FORMULA_409 / sum_dollars;
/*MS5 = sum_ccu / sum_dollars;*/
/*MS6 = sum_FANTASTIK / sum_dollars;*/
run;

data a.ms;
set a.ms;
lnms = log(ms);
lnpine_sol = log(avg_pine_sol);
lnlysol = log(avg_lysol);
lnprivate = log(avg_private);
lnformula_409 = log(avg_formula_409);
/*lnccu = log(avg_ccu);*/
/*lnfantastik = log(fantastik);*/
run;


/************Dummy Variables*************/
data regset;
set a.prod_salesy5;
IF F='A+' then F_Aplus=1; else F_Aplus=0;
IF F='A' then F_A=1; else F_A=0;
IF F='B' then F_B=1; else F_B=0;
IF F='C' then F_C=1; else F_C=0;
IF D=1 then D_minor=1; else D_Minor=0;
IF D=2 then D_major=1; else D_Major=0;
run;

/************ PINE SOL per week*************/

proc sql;
create table PINE_SOL_w as
select week, avg(form_l_d) as form_lqd, avg(form_s_d) as form_spr,
avg(size_l_d) as size_l_d,avg(size_h_d) as size_h_d, avg(pr) as pr, avg(F_aplus) as F_aplus,
avg(F_a) as F_a, avg(F_B) as F_B, avg(F_C) as F_C, avg(D_minor) as D_Minor, avg(D_Major) as D_Major
from regset
where brand = 'PINE SOL'
group by week
order by week;
quit;
/************ LYSOL per week*************/
proc sql;
create table LYSOL_w as
select week, avg(form_l_d) as form_lqd1, avg(form_s_d) as form_spr1,
avg(size_l_d) as size_l_d1,avg(size_h_d) as size_h_d1, avg(pr) as pr1, avg(F_aplus) as F_aplus1,
avg(F_a) as F_a1, avg(F_B) as F_B1, avg(F_C) as F_C1, avg(D_minor) as D_Minor1, avg(D_Major) as D_Major1
from regset
where brand = 'LYSOL'
group by week
order by week;
quit;

/************ FORMULA_409 per week*************/
proc sql;
create table FORMULA_409_w as
select week, avg(form_l_d) as form_lqd2, avg(form_s_d) as form_spr2,
avg(size_l_d) as size_l_d2,avg(size_h_d) as size_h_d2, avg(pr) as pr2, avg(F_aplus) as F_aplus2,
avg(F_a) as F_a2, avg(F_B) as F_B2, avg(F_C) as F_C2, avg(D_minor) as D_Minor2, avg(D_Major) as D_Major2
from regset
where brand = 'FORMULA 409'
group by week
order by week;
quit;

/************ PRIVATE_LABEL per week*************/
proc sql;
create table PRIVATE_LABEL_w as
select week, avg(form_l_d) as form_lqd3, avg(form_s_d) as form_spr3,
avg(size_l_d) as size_l_d3,avg(size_h_d) as size_h_d3, avg(pr) as pr3, avg(F_aplus) as F_aplus3,
avg(F_a) as F_a3, avg(F_B) as F_B3, avg(F_C) as F_C3, avg(D_minor) as D_Minor3, avg(D_Major) as D_Major3
from regset
where brand = 'PRIVATE LABEL'
group by week
order by week;
quit;


/************ Data per week*************/
data a.prob_weekly;
merge PINE_SOL_w  LYSOL_w PRIVATE_LABEL_w  FORMULA_409_w a.MS;
by week; run;

/************Basic Regression*************/
PROC CONTENTS data=a.prob_weekly out=cont; run;

proc reg data = a.prob_weekly;
model lnMS = 
D_Major D_Minor1 F_B F_a f_c f_aplus lnpine_sol lnlysol lnprivate lnformula_409 pr pr1 size_l_d size_h_d
; run;

/************Interaction Term*************/

DATA a.prob_weekly2;
SET a.prob_weekly;
lnMajor = log(D_Major);
lnMinor1 = log(D_Minor1);
lnB = log(F_B);
lnA = log(F_A);
lnpr = log(pr);
lnpr1 = log(pr1);
lnAP=log(F_Aplus);
lnsizeld=log(size_l_d);
lnsizehd=log(size_h_d);
Major_lnpine_sol = lnMajor*lnpine_sol;
Major_lnprivate = lnMajor*lnprivate;
Major_lnlysol = lnMajor*lnlysol;
B_lnpine_sol = lnB*lnpine_sol;
B_lnprivate = lnB*lnprivate;
B_lnlysol = lnB*lnlysol;
A_lnpine_sol = lnA*lnpine_sol;
A_lnprivate = lnA*lnprivate;
A_lnlysol = lnA*lnlysol;
AP_lnpine_sol = lnAP*lnpine_sol;
AP_lnprivate = lnAP*lnprivate;
Pr_lnpine_sol = lnpr*lnpine_sol;
Pr_lnprivate = lnpr*lnprivate;
Pr_lnlysol = lnpr*lnlysol;
B_Major = lnB*lnMajor;
A_Major = lnA*lnMajor;
sizel_lnpinesol = lnsizeld*lnpine_sol;
sizel_lnlysol = lnsizeld*lnlysol;


run;


/*Model to just check own elasticity */
proc reg data = a.prob_weekly2;
model lnMS = 
     lnpine_sol   lnMajor lnB lnA lnMinor1 lnpr lnpr1
; run;

/*Main elasticity model*/
proc reg data = a.prob_weekly2;
model lnMS = 
     lnpine_sol lnprivate lnlysol lnMajor lnB lnA lnMinor1 lnpr lnpr1
	 Major_lnpine_sol Major_lnprivate Major_lnlysol
B_lnpine_sol B_lnprivate 
A_lnpine_sol A_lnprivate 
sizel_lnpinesol sizel_lnlysol
; run;


