
Data cc;
set creditcard;
tfee=totalfee*1.0;run;

/* binary Logit */
proc logistic data=cc;
model active=affinity rewards limit numcard dm ds ts gold platinum quantum;run;


/*Tobit Model*/

data cc;set cc;
limit1=limit/10000;
limit2=limit/100;
tfee1=tfee/100;
profit1=profit/1000;
run;

proc qlim data=cc; 
  Model profit = tfee affinity rewards limit1 numcard dm ds ts gold platinum quantum;
  endogenous profit ~ censored (lb=0);
run;

/* Selection Model */
proc qlim data=cc plots=none; 
	Model active = affinity rewards limit1 numcard dm ds ts gold platinum quantum /discrete;
	Model profit = tfee affinity rewards limit2 numcard dm ds ts gold platinum quantum /select(active=1);
run;
proc means;var limit;class active;run;

data dd;set cc;if limit ne 0;run;
proc qlim data=dd plots=none; 
	Model active = affinity rewards limit1 numcard dm ds ts gold platinum quantum /discrete;
	Model profit1 = tfee1 affinity rewards limit1 numcard dm ds ts gold platinum quantum /select(active=1);
run;
proc means data=dd;run;

/*Reg Model*/
proc reg data=cc;
Model profit = tfee affinity rewards limit numcard dm ds ts gold platinum quantum /stb vif collin;
run;

