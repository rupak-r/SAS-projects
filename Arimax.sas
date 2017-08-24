/*Time series code*/

/*Run this after every arima code to unlock the forecasted dataset*/
data x;
run;
/***********/

data pine_sol_with_display_fy;
set regset;
if Brand ne 'PINE SOL' then delete;
drop form flavor_scent F_Aplus F_A F_B F_C;
run;

proc sort data = pine_sol_with_display_fy;
by week;
run;
proc sql;
create table agg_pine_sol_with_display_fy as
select distinct week, Brand, sum(units) as Units, sum(dollars) as Dollars,avg(d_minor) as Avg_Minor_Display, 
avg(d_major) as Avg_Major_Display,avg(pr) as Avg_Price_Red
from pine_sol_with_display_fy
group by week;
quit;


data LYSOL_price_red_fy;
set regset;
keep week brand pr outlet;
if brand ne 'LYSOL' then delete;
run;
proc sort data = LYSOL_price_red_fy;
by week;
run;
data LYSOL_price_red_fy (rename=(pr = LYSOL_pr));
set LYSOL_price_red_fy;
run;
proc sql;
create table agg_LYSOL_price_red_fy as
select distinct week, avg(LYSOL_pr) as LYSOL_Avg_Price_Red
from LYSOL_price_red_fy
group by week;
quit;
data private_label_price_red_fy;
set regset;
keep week brand pr outlet;
if brand ne 'PRIVATE LABEL' then delete;
run;
proc sort data = private_label_price_red_fy;
by week;
run;
data private_label_price_red_fy (rename=(pr = private_label_pr));
set private_label_price_red_fy;
run;
proc sql;
create table agg_private_label_pr_week_fy as
select distinct week,avg(private_label_pr) as private_label_Avg_Price_Red
from private_label_price_red_fy
group by week;
quit;
data agg_pine_sol_sales_week_fy;
merge agg_pine_sol_with_display_fy agg_LYSOL_price_red_fy agg_private_label_pr_week_fy;
by week;
run;
data agg_pine_sol_sales_week_fy; 
set agg_pine_sol_sales_week_fy; 
d_lysol_avg_price_red=lag(lysol_avg_price_red); 
d_privatelabel_avg_price_red=lag(private_label_avg_price_red); 
run;
/*data agg_pine_sol_sales_week_GR_y5; */
/*set agg_pine_sol_sales_week_GR_y5; */
/*ddollars=dif(dollars); */
/*dunits=dif(units); */
/*run;*/
data agg_pine_sol_sales_week_fy;
set agg_pine_sol_sales_week_fy;
act_unit=units;
act_dollars=dollars;
if week>1139 then units=.;
if week>1139 then dollars=.;
run;

%let y1list = dollars;
%let y2list = units;
%let x1list = avg_display;
%let x2list = avg_price_red;
%let x3list = avg_minor_display;
%let x4list = avg_major_display;
%let x5list = lysol_avg_price_red;
%let x6list = private_label_avg_price_red;
%let dy1list = ddollars;
%let dy2list = dunits;
%let dy3list = d_lysol_avg_price_red;
%let dy4list = d_privatelabel_avg_price_red;
* ARIMA identification;
/*proc arima data=agg_pine_sol_sales_week_GR_y4;*/
/*identify var=&y1list crosscor=(&x1list &x2list) stationarity=(adf);*/
/*identify var=&y2list crosscor=(&x1list &x2list) stationarity=(adf);*/
/*run;*/
proc arima data=agg_pine_sol_sales_week_fy;
identify var=&y1list crosscor=(&x2list &x3list &x4list) stationarity=(adf);
identify var=&y2list crosscor=(&x2list &x3list &x4list) stationarity=(adf);
run;
proc arima data=pine_sol_with_display_fy;
identify var=units crosscor=(pr d_minor d_major) stationarity=(adf);
identify var=dollars crosscor=(pr d_minor d_major) stationarity=(adf);
run;


/*dollars dependent cross corr*/
proc arima data=agg_pine_sol_sales_week_fy;
identify var=dollars crosscor=(avg_price_red avg_minor_display avg_major_display);
estimate p=0 q=0 input=(avg_price_red avg_minor_display avg_major_display) plot method=ML;
forecast lead=26 interval=week out=forecast_pine_sol_dollars_y5;
run;
/*units dependent cross corr*/
proc arima data=agg_pine_sol_sales_week_fy;
identify var=units crosscor=(avg_price_red avg_minor_display avg_major_display);
estimate p=0 q=0 input=(avg_price_red avg_minor_display avg_major_display) plot method=ML;
forecast lead=26 interval=week out=forecast_pine_sol_units_y5;
run;

/*competitor price cross corr*/
proc arima data=agg_pine_sol_sales_week_fy;
identify var=dollars crosscor=(avg_price_red avg_minor_display avg_major_display d_lysol_avg_price_red d_privatelabel_avg_price_red);
estimate p=0 q=0 input=(avg_price_red avg_minor_display avg_major_display d_lysol_avg_price_red d_privatelabel_avg_price_red) plot method=ML;
forecast lead=26 interval=week out=fcast_pine_sol_comp_pr_dlrs_y5;
run;
/*Ar 1 MA 1 with dependent units*/
proc arima data=agg_pine_sol_sales_week_fy;
identify var=units crosscor=(avg_price_red avg_minor_display avg_major_display d_lysol_avg_price_red d_privatelabel_avg_price_red);
estimate p=1 q=1 input=(avg_price_red avg_minor_display avg_major_display d_lysol_avg_price_red d_privatelabel_avg_price_red) plot method=ML;
forecast lead=26 interval=week out=fcast_pine_sol_dplay_AR_MA_y5;
run;
proc arima data=agg_pine_sol_sales_week_fy;
identify var=&y1list crosscor=(&x2list &x3list &x4list &x5list &x6list) NOPRINT;
identify var=&y2list crosscor=(&x2list &x3list &x4list &x5list &x6list) NOPRINT;
estimate p=1 q=1 input=(&x2list &x3list &x4list &x5list &x6list) plot method=ML;
forecast lead=26 interval=week out=forecast_pine_sol_comp_pr_y5;
run;
proc arima data=agg_pine_sol_sales_week_fy;
identify var=&y1list crosscor=(&x2list &x3list &x4list &dy3list &dy4list) NOPRINT;
identify var=&y2list crosscor=(&x2list &x3list &x4list &dy3list &dy4list) NOPRINT;
estimate p=1 q=1 input=(&x2list &x3list &x4list &dy3list &dy4list) plot method=ML;
forecast lead=26 interval=week out=forecast_pine_sol_comp_pr_y5;
run;
/*proc arima data=agg_pine_sol_sales_week_GR_fy;*/
/*identify var=&y1list;*/
/*identify var=&y2list;*/
/*estimate p=1 q=2;*/
/*run;*/

/*Durbin watson test*/
proc reg data=agg_pine_sol_sales_week_fy;
model units = avg_minor_display avg_major_display avg_price_red lysol_avg_price_red private_label_avg_price_red d_lysol_avg_price_red d_privatelabel_avg_price_red;
run;
proc reg data=agg_pine_sol_sales_week_fy;
model units = avg_minor_display avg_major_display avg_price_red /DW ;
run;
/* Grocery only*/

data pine_sol_with_display_yh1;
set regset_pine_sol;  
drop form flavor_scent F_Aplus F_A F_B F_C;
if week > 1139 then delete;
run;
proc sort data = pine_sol_with_display_yh1;
by week;
run;
/*proc sql;*/
/*create table agg_pine_sol_sales_week_yh1 as*/
/*select distinct week, Brand, sum(units) as Units, sum(dollars) as Dollars,avg(d_minor) as Avg_Minor_Display, */
/*avg(d_major) as Avg_Major_Display,avg(pr) as Avg_Price_Red*/
/*from pine_sol_with_display_yh1*/
/*group by week;*/
/*run;*/

data pine_sol_with_display_yh2;
set regset_pine_sol;  
drop form flavor_scent F_Aplus F_A F_B F_C;
if week <=1139 then delete;
run;





proc sql;
create table agg_pine_sol_display_week_GR_y4 as
select distinct week, Brand, avg(d_minor) as Avg_Minor_Display, avg(d_major) as Avg_Major_Display
from pine_sol_with_display_yh1
where outlet in ('Gr','GR')
group by week;
run;
proc sql;
create table agg_pine_sol_sales_week_GR_y4 as
select distinct week, Brand, sum(units) as Units, sum(dollars) as Dollars,avg(d) as Avg_Display, avg(pr) as Avg_Price_red
from pine_sol_with_display_yh1
where outlet in ('Gr','GR')
group by week;
run;
data agg_pine_sol_sales_week_GR_y4;
merge agg_pine_sol_sales_week_GR_y4 agg_pine_sol_display_week_GR_y4;
by week;
run;
proc sql;
create table agg_pine_sol_display_week_GR_y5 as
select distinct week, Brand, avg(d_minor) as Avg_Minor_Display, avg(d_major) as Avg_Major_Display
from pine_sol_with_display_yh2
where outlet in ('Gr','GR')
group by week;
quit;
proc sql;
create table agg_pine_sol_sales_week_GR_y5 as
select distinct week, Brand, sum(units) as Units, sum(dollars) as Dollars,avg(d) as Avg_Display, avg(pr) as Avg_Price_red
from pine_sol_with_display_yh2
where outlet in ('Gr','GR')
group by week;
quit;
data agg_pine_sol_sales_week_GR_y5;
merge agg_pine_sol_sales_week_GR_y5 agg_pine_sol_display_week_GR_y5;
by week;
run;
 * Creating a differenced variable;
/*agg_pine_sol_sales_week_GR_y4*/

data agg_pine_sol_sales_week_GR_y4; 
set agg_pine_sol_sales_week_GR_y4; 
ddollars=dif(dollars); 
dunits=dif(units); 
run;
data agg_pine_sol_sales_week_y4; 
set agg_pine_sol_sales_week_y4; 
d_lysol_avg_price_red=lag(lysol_avg_price_red); 
d_privatelabel_avg_price_red=lag(private_label_avg_price_red); 
run;
data agg_pine_sol_sales_week_GR_y5; 
set agg_pine_sol_sales_week_GR_y5; 
ddollars=dif(dollars); 
dunits=dif(units); 
run;
data agg_pine_sol_sales_week_GR_y5;
set agg_pine_sol_sales_week_GR_y5;
act_unit=units;
act_dollars=dollars;
units=.;
dollars=.;
run;

data agg_pine_sol_sales_week_GR_y4; 
set agg_pine_sol_sales_week_GR_y4 agg_pine_sol_sales_week_GR_y5; 
run;
/*data agg_pine_sol_sales_week_GR_y4;*/
/*set agg_pine_sol_sales_week_GR_y4;*/
/*if avg_price_red=. then avg_price_red=avg_price;*/
/*run; */
%let y1list = dollars;
%let y2list = units;
%let x1list = avg_display;
%let x2list = avg_price_red;
%let x3list = avg_minor_display;
%let x4list = avg_major_display;
%let x5list = lysol_avg_price_red;
%let x6list = private_label_avg_price_red;
%let dy1list = ddollars;
%let dy2list = dunits;
%let dy3list = d_lysol_avg_price_red;
%let dy4list = d_privatelabel_avg_price_red;
* ARIMA identification;
proc arima data=agg_pine_sol_sales_week_GR_y4;
identify var=&y1list crosscor=(&x1list &x2list) stationarity=(adf);
identify var=&y2list crosscor=(&x1list &x2list) stationarity=(adf);
run;


/* ARIMA(0,0,0) or ARMA(0,0) */
proc arima data=agg_pine_sol_sales_week_GR_y4;
identify var=&y1list;
identify var=&y2list;
estimate p=0 q=0;
run;
/*data agg_pine_sol_sales_week_GR_y4 (rename=(Avg_Price=Avg_Price_Red));*/
/*set agg_pine_sol_sales_week_GR_y4;*/
/*run;*/
/*data test;*/
/*set forecast_pine_sol_display_y5;*/
/*label forecast = forecast for units;*/
/*run;*/
proc arima data=agg_pine_sol_sales_week_GR_y4;
identify var=&y1list crosscor=(&x2list &x3list &x4list) ;
identify var=&y2list crosscor=(&x2list &x3list &x4list) ;
estimate p=1 q=1 input=(&x2list &x3list &x4list) plot method=ML;
forecast lead=26   interval=week out=forecast_pine_sol_display_y5;
run;

proc arima data=agg_pine_sol_sales_week_GR_y4;
identify var=&y1list;
identify var=&y2list;
estimate p=1 q=2;
run;

/*Have to check below one after including lysol and private price at Gr level*/

/*proc arima data=agg_pine_sol_sales_week_GR_y4;*/
/*identify var=units crosscor=(avg_price_red avg_minor_display avg_major_display lysol_avg_price_red private_label_avg_price_red) stationarity=(adf);*/
/**identify var=dollars crosscor=(avg_price_red avg_minor_display avg_major_display lysol_avg_price_red private_label_avg_price_red) stationarity=(adf);**/
/*estimate p=0 q=0 input=(avg_price_red avg_minor_display avg_major_display lysol_avg_price_red private_label_avg_price_red) plot method=ML;*/
/*forecast lead=26 interval=week out=forecast_pine_sol_units_y5;*/
/*run;*/


/* End of time series */
