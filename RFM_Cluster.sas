

data a.panel ( drop = panid);
/*set p1 p2 p3 ; */
set p1 p2;
panid_1 = put(panid , 8.0);
run;
proc sql;
create table a.RFM as
select panid_1,max(week)as RecentWeek,sum(dollars) as TotalAmount,count(*) as TotalPurchases
from a.panel
group by panid_1;
quit;

/* Sample Code for RFM - start */ 
proc rank data=a.RFM out=a.rdata groups=5;
var recentweek;
ranks recencyscore;
run;
proc rank data=a.rdata out=a.rfdata groups=5;
var totalpurchases;
ranks freqscore;
run;

proc rank data=a.rfdata out=a.rfmdata groups=5;
var totalamount;
ranks monetaryscore;
run;
 

data a.rfm_mod;
set a.rfmdata;
recencyscore1 = recencyscore + 1;
freqscore1 = freqscore + 1;
monetaryscore1 = monetaryscore + 1;
run;

data a.temp;
set a.rfm_mod;
recency_score = put(recencyscore1 , 6.);
freq_score = put(freqscore1 , 6.);
monetary_score = put(monetaryscore1 , 6.);
run;


data a.rfmfinal;
set a.temp;
RFMScore = cats(recency_score,freq_score,monetary_score);
RFM_Score = RFMScore;
run;



proc sort data = a.rfmfinal_mod;
by descending rfm_score;
run;
data a.rfmfinal_mod(drop = panid freqscore1 monetaryscore1 recencyscore1 freqscore monetaryscore recencyscore rfmscore);
set a.rfmfinal;
label panid_1  ="Customer ID"
			totalamount = "Sum of Transaction Amounts"
			recentweek = "Week of Most Recent Transaction"
          recency_score = "Recency Score(1=Least Recent,5=Most Recent)" 
		  freq_score = "Frequency Score(1=Least Frequent,5=Most Frequent)" 
		  monetary_score = "Monetary Score(1=Lowest Amount,5=Highest Amount)" 
          rfm_score = "RFM Score";
run;
proc sort data=a.rfmfinal_mod;
by descending rfm_score;
run;
data a.rfmfinal_clus(drop = recency_score freq_score monetary_score);
set a.rfmfinal_mod;
recency_score_1 = recency_score*1.0;
freq_score_1 = freq_score*1.0;
monetary_score_1 = monetary_score*1.0;
run;

/* hierarchichal Cluster analysis */
proc cluster data=a.rfmfinal_clus method=AVERAGE PSEUDO PLOTS=CCC NOTIE k=3000; 
	var recency_score_1 freq_score_1 monetary_score_1;
	copy panid_1 rfm_score;
run;
proc tree data=a.clusters;
	id PANID_1;
run;

proc contents data = a.rfmfinal_mod;
/* non-hierarchichal Cluster analysis */
proc fastclus data=a.rfmfinal_clus maxc=4 maxiter=100 replace=full out = a.rfm_clus_num;
	var recency_score_1 freq_score_1 monetary_score_1;
	id panid_1;
	run;

PROC IMPORT OUT= a.demo 
            DATAFILE= "C:\Srini\Study_Spring17\Mkt Predictive InClass\hhclean\ads demo1.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

data a.demo_mod(drop = panelist_id);
set a.demo;
panelist_id_1 = put(panelist_id , 8.0);
run;

proc sql;
create table a.rfm_demo as
select * from a.demo_mod a inner join a.rfm_clus_num b
on a.panelist_id_1=b.panid_1;
quit;

proc means data=a.rfm_demo;
class cluster;
run;
