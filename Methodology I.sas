
*Creation of dummy variabels;

DATA weather;
length Formatted_Date $30.;
length summary $30.;
length daily_Summary $40.;
INFILE "U:\project\weather.csv" DELIMITER =',' MISSOVER FIRSTOBS=2;
INPUT Formatted_Date Summary $ Precip_type $ Temperature_c Apparent_temperature__C_ Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Loud_Cover Pressure__millibars_ Daily_Summary $;
Wmonth=substr(Formatted_Date,6,2);
format time_numeric time8.;
time_numeric = input(substr(Formatted_Date,12,2) !! ':' !! substr(Formatted_Date,15,2) !! ':' !! substr(Formatted_Date,18,2),time8.);
Snow = ( Precip_type = "snow");
Breeze = ( Summary = "Breezy");
B_MC = ( Summary = "Breezy and Mostly Cloudy");
B_OC = ( Summary = "Breezy and Overcast ");
B_PC = ( Summary = "Breezy and Partly Cloudy");
Clr = ( Summary = "Clear");
Drizzle = (Summary = "Drizzle");
Fog = ( Summary = " Foggy");
HMC = (Summary = " Humid and Mostly Cloudy");
H_OC = (Summary = "Humid and Overcast");
Lgt_rain = ( Summary = "Light Rain");
MC = (Summary = "Mostly Cloudy");
OC = (Summary = "Overcast");
PCld = (Summary = "Partly Cloudy");
RN = (Summary = "Rain");
run;
PROC PRINT;
RUN;

TITLE "Select only the required months [month-JAN, FEB, MAR] ";
proc sql;
delete from weather
where wmonth not IN ('01','02','03');
QUIT;
PROC PRINT;
RUN;

TITLE'Sorts the data Formatted_Date in Ascending Order';
PROC SORT DATA= weather OUT=Sort_Weather;
By Formatted_Date;
PROC PRINT;
RUN;

TITLE'Histogram of Temperature_c';

proc univariate normal;
var Temperature_c;
histogram / normal (mu=est sigma=est);
run;

*Verifying full model(with dummy variables);
TITLE "Full Model";
proc reg;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Loud_Cover Pressure__millibars_ time_numeric Snow Breeze B_MC B_OC B_PC Clr Drizzle Fog HMC H_OC Lgt_rain MC OC PCld RN;
run;
QUIT;

TITLE'taining and testing data set';
proc surveyselect 
data = weather out = Nwether_123 seed = 231201
samprate = 0.80 outall;
proc print;
run; 
TITLE'Check the frequency ';
proc freq data = Nwether_123;
run;

TITLE'print Nweather for month 1,2,3';
proc print data = Nwether_123;
run;
TITLE'Printing Training dataset of weathernew - weather_Train1';
data weather_Train1
(where = ( selected = 1 ));
set Nwether_123;
run;
proc print data = weather_Train1;
run;
TITLE "Histogram for Temperature - training data set";
proc univariate normal;
var Temperature_c;
histogram / normal (mu=est sigma=est);
run;
TITLE"Boxplot of temp vs months in Jan feb and March ";
PROC BOXPLOT;
PLOT Temperature_c*wmonth;
RUN;

TITLE "Correlation values for tarining set";
proc corr;
var Temperature_c Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ time_numeric Snow Breeze B_MC B_OC B_PC Clr Drizzle Fog HMC H_OC Lgt_rain MC OC PCld RN;
run; 

TITLE "Full Model for training set";
proc reg data = weather_Train1;
model Temperature_c = Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ time_numeric Snow Breeze B_MC B_OC B_PC Clr Drizzle Fog HMC H_OC Lgt_rain MC OC PCld RN;
run;

TITLE "training set -step wise ";
*Model 1  step wise ;
proc reg data = weather_Train1;
model Temperature_c = Humidity Wind_Speed_km_h_  Visibility_km_ Pressure__millibars_ time_numeric Snow Breeze Clr Drizzle Fog H_OC Lgt_rain MC OC RN/selection = stepwise;
run;

TITLE " training set  -backward ";
*Model 1  backword ;
* this method giving the same resuts as stepwise;
proc reg data = weather_Train1;
model Temperature_c = Humidity Wind_Speed_km_h_  Visibility_km_ Pressure__millibars_ time_numeric Snow Breeze Clr Drizzle Fog H_OC Lgt_rain MC OC RN/selection = backward;
run;


TITLE ' Refit model(M1) - getting influential points and outliers ';
proc reg data = weather_Train1;
model Temperature_c = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC / influence r ;
run;
* resudual Analysis model 1;
TITLE'Studentised Resudual plots for model1';
proc reg;
model Temperature_c = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC;
plot student.*(Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC) ;
run;


TITLE'Studentised vs predicted values plots';
proc reg;
model Temperature_c = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC;
plot student.*predicted.; 
run;

TITLE'Normality plot for model1';
proc reg;
model Temperature_c = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC;
plot npp.*predicted.; 
run;

title 'transformation y square';
data weather_Train1;
set weather_Train1;
y_sqrt = Temperature_c **2;
run;

TITLE'Normality plots after transformation( y square)';
* r square and adj r2 decreased for the model 1 ;
proc reg;
model y_sqrt = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC;
plot npp.*predicted.; 
run;

title 'transformation via log';
data weather_Train1;
set weather_Train1;
Log_Y = log(Temperature_c);
run;

TITLE'Normality plots after transformation( log y)';

proc reg;
model Log_Y =  Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC;
plot npp.*predicted.; 
run;
* model prediction for stepwise M1;
* i have removed insignificant variables to use gmselect of model 2;
TITLE'prediction model 1 training set';
data pred; 
input Temperature_c Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC; 
datalines; 
. 1.00 11.1090 6.1985 1017.78 0 0 0 0 1
;
*this prediction shows me that if the overcast is there and visibility is good then there wont be a rain and temprature should be closer to 10;
* this observation is same as observation 1 in training data set;
data new;
set pred weather_Train1;
run; 
proc reg data = new;
model Temperature_c = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC/p clm cli alpha=0.05; 
run;
TITLE ' MODEL 2 - Interaction terms';
proc glmselect data = weather_Train1;
model  Temperature_c = Humidity|Wind_Speed_km_h_|Visibility_km_|Pressure__millibars_|time_numeric|Snow|Clr|MC|OC @3 / selection = stepwise(stop=cv);
run;


*defining variables name ;
data Nwether_123;
set Nwether_123;
hwp = Humidity*Wind_Speed_km_h_*Pressure__millibars_;
hs = Humidity*Snow;
ps = Pressure__millibars_*Snow;
tmc  = time_numeric*MC;
vtmc = Visibility_km_*time_numeric*MC;
ptmc = Pressure__millibars_*time_numeric*MC;
vsmc = Visibility_km_*Snow*MC;
hoc = Humidity*OC;
htoc = Humidity*time_numeric*OC;
soc = Snow*OC;
run;
TITLE'prediction model 2 training set';
data pred; 
input Temperature_c Humidity Wind_Speed_km_h_ hwp hs ps tmc vtmc ptmc vsmc hoc htoc soc; 
datalines; 
. 1.00 11.1090 1 0 0 0 1 1 0 1 1 1
;

data new;
set pred Nwether_123;
run; 
proc reg data = new;
model Temperature_c = Humidity Wind_Speed_km_h_ hwp hs ps tmc vtmc ptmc vsmc hoc htoc soc/p clm cli alpha=0.05; 
run;

Title"new y(temp) ";
data Nwether_123;
set Nwether_123;
if selected then new_temp = Temperature_c;
run;

title "Evaluating test set";
proc reg data=Nwether_123;
model  new_temp = Humidity Wind_Speed_km_h_ hwp hs ps tmc vtmc ptmc vsmc hoc htoc soc;
output out = outm2(where=(new_temp=.)) p=yhat;

model new_temp = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC;;
output out = outm1(where=(new_temp=.)) p=yhat;
run;
TITLE'Testing data set p hat values';
proc print data = outm1;
* outm1 deifines data set containg model 1 predicted values for the test set;
run;
proc print data = outm2;
* outm2 deifines data set containg model 2 predicted values for the test set;
run;


* next task is to get difference for two models in test set;
* this values will gives me the performance test stasts RMSE MAE R2 for TEST SET;
* this is model 1 of testing data set N=436 to get RMSE r2 MAE values; 
Title'difference between observed and predicted val in test set';
data outm1_sum;
set outm1;
d = Temperature_c -  yhat;
absd = abs(d);
run;
proc summary data = outm1_sum;
var d absd;
output out = outm1_stats std(d) = rmse mean(absd) = mae;
run;
proc print data = outm1_stats;
TITLE'Validation statastics for model1';
run;
proc corr data = outm1;
var Temperature_c yhat;
run;

* this is model 2 of testing data set N=436 to get RMSE r2 MAE values; 
Title'difference between observed and predicted val in test set';
data outm2_sum;
set outm2;
d = Temperature_c -  yhat;
absd = abs(d);
run;
proc summary data = outm2_sum;
var d absd;
output out = outm2_stats std(d) = rmse mean(absd) = mae;
run;
proc print data = outm2_stats;
TITLE'Validation statastics for model2';
run;
proc corr data = outm2;
var Temperature_c yhat;
run;


* performing on test data set;
TITLE'5 - fold cross validation for model selection - step wise';
proc glmselect data = Nwether_123
plots = (aseplot Criteria);
* generate ASE plots;
partition fraction ( test = 0.20);
model Temperature_c = Humidity Wind_Speed_km_h_ Visibility_km_ Pressure__millibars_ time_numeric Snow Clr MC OC /selection = stepwise( stop = cv) cvMethod = split(5) cvDetails = all;
run;




