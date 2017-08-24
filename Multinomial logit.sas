Data Ketchup;
infile "H:\HW5\ketmk1l20.dat";
input HID STID WEEK BR P1  P2 P3 P4 D1 D2 D3 D4 F1 F2 F3 F4 INC NMEMB TOT DOLSPENT KID L1 L2 L3 L4;
run;

data newdata (keep=hid tid decision mode price display feature loyalty inc nmemb kid);
set ketchup;
array pvec{4} p1 - p4;
array dvec{4} d1 - d4;
array fvec{4} f1 - f4;
array lvec{4} l1 - l4;
retain tid 0;
tid+1;
do i = 1 to 4;
	mode=i;
	price=pvec{i};
	display=dvec{i};
	feature=fvec{i};
	loyalty=lvec{i};
	decision=(br=i);
	output;
end;
run;

data newdata;
set newdata;
br2=0;
br3=0;
br4=0;
if mode = 2 then br2 = 1;
if mode = 3 then br3 = 1;
if mode = 4 then br4 = 1;
inc2=inc*br2;
inc3=inc*br3;
inc4=inc*br4;
kid2=kid*br2;
kid3=kid*br3;
kid4=kid*br4;
nmemb2=nmemb*br2;
nmemb3=nmemb*br3;
nmemb4=nmemb*br4;
run;

/* MNL model */
proc mdc data=newdata;
model decision = br2 br3 br4 price display feature loyalty inc2-inc4 nmemb2-nmemb4 kid2-kid4/ type=clogit 
	nchoice=4;
	id tid;
	output out=probdata pred=p;
run;

/* Mixed model */
proc mdc data=newdata;
model decision = br2 br3 br4 price display feature loyalty inc2-inc4 nmemb2-nmemb4 kid2-kid4/ type=MXL mixed=(normalparm=price display feature)nchoice=4;
id tid;
run;
	
proc sql;
create table predict as
select p, tid, decision
from probdata
order by tid, p desc;
run;
quit;

data predict;
set predict;
predict=0;
by tid;
if first.tid then predict=1;
run;

proc freq data=predict;
table predict*decision;
run;
