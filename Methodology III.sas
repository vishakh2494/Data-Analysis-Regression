*Keertika Rai: Project Code;
title "Separate date and time";
DATA weather;
length Formatted_Date $30.;
length summary $30.;
length daily_Summary $40.;
INFILE "weather.csv" DELIMITER =',' MISSOVER FIRSTOBS=2;
INPUT Formatted_Date Summary $ Precip_type $ Temperature_c Apparent_temperature__C_ Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Loud_Cover Pressure__millibars_ Daily_Summary $;
Wmonth=substr(Formatted_Date,6,2);
format time_numeric time8.;
time_numeric = input(substr(Formatted_Date,12,2) !! ':' !! substr(Formatted_Date,15,2) !! ':' !! substr(Formatted_Date,18,2),time8.);
DPrecip = ( Precip_type = "snow");
DBreezy = ( Summary = "Breezy");
DB_M_Cloudy = ( Summary = "Breezy and Mostly Cloudy");
DB_Cast = ( Summary = "Breezy and Overcast ");
DB_P_Cloudy = ( Summary = "Breezy and Partly Cloudy");
DClr = ( Summary = "Clear");
DDrizzle = (Summary = "Drizzle");
DFroggy = ( Summary = " Froggy");
DHum_Cast = (Summary = "Humid and Overcast");
DL_Rain = ( Summary = "Light Rain");
DM_Cloudy = (Summary = "Mostly Cloudy");
DCast = (Summary = "Overcast");
DP_Cloudy = (Summary = "Partly Cloudy");
DRain = (Summary = "Rain");
run;
proc print;
run;

title "Select only the required months ";
proc sql;
create table weathernew as
select * from weather
where wmonth IN ('07','08','09');
QUIT;
proc print;
run;

TITLE'Spliting dataset into Training and Testing dataset';
proc surveyselect data = weathernew out = New_Weather789 seed = 415217 samprate = 0.80 outall;
proc print;
run;

TITLE'Training dataset of New_Weather789';
data weathernew_Train1
(where = ( selected = 1 ));
set New_Weather789;
run;
proc print data = weathernew_Train1;
run;

TITLE "Histogram for Temperature";
proc univariate normal;
var Temperature_c;
histogram / normal (mu=est sigma=est);
run;

TITLE "Boxplot - time_numeric and Temperature_c";
proc sort;
by time_numeric;
run;
proc boxplot;
plot Temperature_c*time_numeric;
run;

TITLE "Boxplot - WMonth and Temperature_c";
proc sort;
by WMonth;
run;
proc boxplot;
plot Temperature_c*WMonth;
run;

TITLE "Correlation values";
proc corr;
var Temperature_c Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ time_numeric DClr DM_Cloudy DCast DP_Cloudy;
run; 

TITLE "Full Model";
proc reg;
model Temperature_c = Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ time_numeric DClr DM_Cloudy DCast DP_Cloudy/stb;
run;

TITLE "Prediction Model 1 Training Set";
data pred;
input Temperature_c Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy;
datalines;
. 0.70 3.6708 10 15.5526 1019.55 0 0 0 1 
;
data new;
set pred weathernew_Train1;
run;
proc reg;
model Temperature_c= Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy/p clm cli alpha=0.05;
run;


TITLE "Residual Analysis";
proc reg;
model Temperature_c = Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy;
*Residual Plot: residuals vs predicted values;
plot student.*predicted.;
*Residual Plot: residuals vs x variables;
*Linearity, Independence, Constant Variance Assumptions;
plot student.*(Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy);
*Normal Probability Plot or QQ Plot;
*Normality Assumption;
plot npp.*student.;
run;

TITLE "Interaction Variables";
proc glmselect;
model Temperature_c = Wind_Speed_km_h_|Wind_Bearing_degrees_|Visibility_km_ Humidity|Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy @3 / selection = stepwise(stop=cv);
run;

TITLE "Prediction Model 2 Training Set";
data pred;
input Temperature_c Wind_Speed_km_h_ Visibility_km_ wsv Humidity Pressure__millibars_ hpm DP_Cloudy;
datalines;
. 10.9963 16.1 0.71 1013.95 0
;
data new;
set pred weathernew_Train1;
run;
proc reg;
model Temperature_c= Temperature_c Wind_Speed_km_h_ Visibility_km_ wsv Humidity Pressure__millibars_ hpm DP_Cloudy/p clm cli alpha=0.05;
run;


TITLE"Create new_temp";
data New_Weather789;
set New_Weather789;
if selected then new_temp=Temperature_c;
run;
proc print data= New_Weather789;
run;

data New_Weather789;
set New_Weather789;
hws = Humidity*Wind_Speed_km_h_;
wsv = Wind_Speed_km_h_*Visibility_km_;
hpm = Humidity*Pressure__millibars_;
run;


TITLE "Validation-test set";
proc reg data=New_Weather789;
*Model 1;
model new_temp = Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy;
output out = outm1(where=(new_temp=.)) p=yhat;
*Model 2;
model new_temp = Wind_Speed_km_h_ Visibility_km_ wsv Humidity Pressure__millibars_ hpm DP_Cloudy;
output out = outm2(where=(new_temp=.)) p=yhat;
run;

TITLE'Difference between Observed and Predicted in Test Set- Model1';
data outm1_sum;
set outm1;
*d is the difference between observed and predicted values in test set;
d = Temperature_c -  yhat;
absd = abs(d);
run;
proc summary data = outm1_sum;
var d absd;
output out = outm1_stats std(d) = rmse mean(adsd) = mae;
run;
proc print data = outm1_stats;
TITLE'Validation statistics for model';
run;
proc corr data = outm1;
var Temperature_c yhat;
run;

TITLE' Difference between Observed and Predicted in Test Set- Model2';
data outm2_sum;
set outm2
d = Temperature_c -  yhat;
absd = abs(d);
run;
proc summary data = outm2_sum;
var d absd;
output out = outm2_stats std(d) = rmse mean(adsd) = mae;
run;
proc print data = outm2_stats;
TITLE'Validation statistics for model';
run;
proc corr data = outm2;
var Temperature_c yhat;
run;

TITLE'5 - fold cross validation for model selection - step wise';
proc glmselect data = New_Weather789
plots = (aseplot Criteria);
* generate ASE plots;
partition fraction ( test = 0.20);
model Temperature_c = Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy /
selection = stepwise( stop = cv) cvMethod = split(10) cvDetails = all;
run;

TITLE'5 - fold cross validation for model selection - backward';
proc glmselect data = New_Weather789
plots = (aseplot Criteria);
* generate ASE plots;
partition fraction ( test = 0.20);
model Temperature_c = Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ DClr DM_Cloudy DCast DP_Cloudy /
selection = backward( stop = cv) cvMethod = split(10) cvDetails = all;
run;
