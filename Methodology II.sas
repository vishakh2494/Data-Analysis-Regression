*MODEL 1;

*Import of data and creation of dummy variables;
DATA weather;
length Formatted_Date $30.;
length summary $30.;
length daily_Summary $40.;
INFILE "weather.csv" DELIMITER =',' MISSOVER FIRSTOBS=2;
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
where wmonth not IN ('04','05','06');
QUIT;
PROC PRINT;
RUN;

TITLE'Sorts the data Formatted_Date in Ascending Order';
PROC SORT DATA= weather OUT=Sort_Weather;
By Formatted_Date;
PROC PRINT;
RUN;

TITLE'Creation of Histogram (with dummy variables)';
proc univariate normal;
var Temperature_c;
histogram / normal (mu=est sigma=est);
run;

TITLE "Boxplots - Temp vs wmonth";
PROC SORT;
BY Wmonth;
RUN;
PROC BOXPLOT;
PLOT Temperature_c*Wmonth ;
RUN;

TITLE "Boxplots - Temp vs time_numeric";
PROC SORT;
BY time_numeric;
RUN;
PROC BOXPLOT;
PLOT Temperature_c*time_numeric ;
RUN;

*Splitting the Data into Test and Training;
TITLE'taining and testing data set';
proc surveyselect 
data = weather out = Nwether_456 seed = 231201
samprate = 0.80 outall;
proc print;
run;

TITLE'print Nweather for month 4,5,6';
proc print data = Nwether_456;
run;

TITLE'Extraction of Training Set Data Observations';
data weather_Train1
(where = ( selected = 1 ));
set Nwether_456;
run;
proc print data = weather_Train1;
run;

*Histogram Generation;
TITLE "Histogram for Temperature - training data set";
proc univariate normal;
var Temperature_c;
histogram / normal (mu=est sigma=est);
run;

*Verifying full model(for Training dataset);
TITLE "Full Model";
proc reg;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ 
Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ time_numeric   
B_MC B_OC B_PC Clr H_OC MC OC PCld ;
run;
QUIT;

*Model Selection Methods;
TITLE "Full Model";
proc reg;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ 
Wind_Bearing_degrees_ Visibility_km_ Pressure__millibars_ time_numeric   
B_MC B_OC B_PC Clr H_OC MC OC PCld /selection=STEPWISE;
run;
QUIT;

*Fitting the final model with significant predictors;
TITLE "Final Model";
proc reg;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC;
run;
QUIT;

*5-Fold Cross Validation;
TITLE "5-FOld Cross Validation";
PROC glmselect data=weather
plots=(asePlot Criteria);
partition fraction (test=0.25);
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC; / selection=stepwise(stop=cv)
cvMethod=split(5) cvDetails=all;
RUN;


*Final Model (Provides Correlation Values);
TITLE "Correlation values";
proc corr;
Var Temperature_c  Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC;
run; 

*Verifcation of Standardized Estimates;
proc reg;
model Temperature_c =  Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC /stb;
run;
QUIT;

*Verification of Tolerance Values;
proc reg;
model Temperature_c =  Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC /tol;
run;
QUIT;

*Verification of Outliers,influential points,multicollinearity;
PROC reg data=weather;
model Temperature_c =  Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC / influence r vif;
plot student.*( Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC predicted.);
plot npp.*student.;
run;

*Enables to remove the outlier/influential points;
DATA NewWeather;
SET weather;
if _n_=1573 then delete;
run;

TITLE "Residual Analysis";
PROC REG;
model Temperature_c =  Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC;
 plot student.* predicted.;
 plot student.*(Apparent_temperature__C_ Humidity Wind_Speed_km_h_    
 B_OC MC OC);
 plot npp.*student.;
 run;

*TESTING DATASET PROCEDURE;

*Procedure for extraction of Test set data observations;
TITLE'Test Set Data Observations - weather_Test1';
data weather_Test1
(where = ( selected = 0 ));
set Nwether_456;
run;
proc print data = weather_Test1;
run;

data pred;      
input Temperature_c Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_OC MC OC;
datalines; 
. 11.8056 0.71 10.9963 0 0 0 
;

data new;
set pred weather_Test1;
run;

proc reg;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_OC MC OC /p clm cli alpha=0.05; 
run;


*VALIDATION TESTING;

Title"new y(temp) ";
data Nwether_456;
set Nwether_456;
if selected then new_temp = Temperature_c;
run;
PROC PRINT;
RUN;

*MODEL 1;
title "Evaluating test set";
proc reg data=Nwether_456;
model  new_temp = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_OC MC OC;
output out = outm2(where=(new_temp=.)) p=yhat;


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
TITLE'Validation statastics for model1';
run;
proc corr data = outm2;
var Temperature_c yhat;
run;






*MODEL 2;

TITLE "DataSet Import";
DATA weather;
length Formatted_Date $30.;
length summary $30.;
length daily_Summary $40.;
INFILE "weather.csv" DELIMITER =',' MISSOVER FIRSTOBS=2;
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
H_OC = (Summary = "Humid and Overcast");
Lgt_rain = ( Summary = "Light Rain");
MC = (Summary = "Mostly Cloudy");
OC = (Summary = "Overcast");
PCld = (Summary = "Partly Cloudy");
RN = (Summary = "Rain");
run;
PROC PRINT;
RUN;

title "Selection of required months [month-April, May, June] ";
proc sql;
delete from weather
where wmonth not IN ('04','05','06');
QUIT;
PROC PRINT;
RUN;

*Sorts the data Formatted_Date in Ascending Order;
PROC SORT DATA= weather OUT=Sort_Weather;
By Formatted_Date;
PROC PRINT;
RUN;

*Generates Interaction variables;
TITLE "Interaction Variables";
proc glmselect;
model Temperature_c = Apparent_temperature__C_| Humidity|Wind_Speed_km_h_|Wind_Bearing_degrees_|Visibility_km_|Pressure__millibars_|time_numeric| B_MC| B_OC| B_PC| Clr| Drizzle| Fog| H_OC | Lgt_rain| MC| OC| PCld| RN @3 / selection = stepwise(stop=cv);
run;

*Adding the Interaction terms for the existing dataset;
data weather;
set weather;
IV1 = Apparent_temperature__C_*Wind_Speed_km_h_;
IV2 = Humidity*Wind_Speed_km_h_;
IV3 = Apparent_temperature__C_*Humidity*Wind_Speed_km_h_;
IV4 = Apparent_temperature__C_*time_numeric*MC;
IV5 = Humidity*time_numeric*MC;
IV6 =Pressure__millibars_*time_numeric*MC;
run;
PROC PRINT;
RUN;

*Creation of Histogram (with dummy & Interaction variables);
TITLE "Histogram for Temperature";
proc univariate normal;
var Temperature_c;
histogram / normal (mu=est sigma=est);
run;

*Splitting the Data into Test and Training;
TITLE'taining and testing data set';
proc surveyselect 
data = weather out = Nwether_456 seed = 231201
samprate = 0.80 outall;
proc print;
run;

TITLE'Extraction of Training Set from the split operation';
data weather_Train2
(where = ( selected = 1 ));
set Nwether_456;
run;
proc print data = weather_Train2;
run;

*Full Model;
TITLE "Full Model";
proc reg data=weather_Train2;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ 
Visibility_km_ Loud_Cover Pressure__millibars_ time_numeric Snow Breeze 
B_MC B_OC B_PC Clr Drizzle Fog H_OC Lgt_rain MC OC PCld RN IV1 IV2 IV3 IV4 IV5 IV6;
run;
QUIT;

*SELECTION METHODS;
TITLE "Full Model";
proc reg;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ Wind_Bearing_degrees_ 
Visibility_km_ Loud_Cover Pressure__millibars_ time_numeric Snow Breeze 
B_MC B_OC B_PC Clr Drizzle Fog H_OC Lgt_rain MC OC PCld RN IV1 IV2 IV3 IV4 IV5 IV6/selection=backward;
run;
QUIT;

*Final Fitted Model;
TITLE "Fit Model";
proc reg data=weather_Train2;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6;
run;
QUIT;

*5-Fold Cross Validation;
TITLE "5-FOld Cross Validation";
PROC glmselect data=weather
plots=(asePlot Criteria);
partition fraction (test=0.25);
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6 / selection=stepwise(stop=cv)
cvMethod=split(5) cvDetails=all;
RUN;

*Verification of Residual Analysis Plots;
TITLE "Residual Analysis";
proc reg; 
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6;
plot Student.* predicted.; 
plot Student.*(Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6);
plot npp.* Student.;
run;

*Verification of Association/Correlation;
PROC corr;
Var Temperature_c Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6;
RUN;
Quit;

PROC gplot;
plot Temperature_c*(Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6);
run;

PROC sgscatter;
matrix Temperature_c Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6;
run;

*Verification of Outliers, influential points, multicollinearity;
PROC reg data=weather_Train2;
model Temperature_c = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6 / influence r tol stb vif;
plot student.*(Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6 predicted.);
plot npp.*student.;
run;

*Enables to remove the outlier/influential points;
DATA NewWeather;
SET weather;
if _n_=1573 then delete;
run;

*TESTING PHASE;

*Prediction Procedure;
TITLE'Printing Training dataset of weathernew - weather_Train1';
data weather_Test2
(where = ( selected = 0 ));
set Nwether_456;
run;
proc print data = weather_Test2;
run;

*Confidence Intervals, Prediction Intervals, Prediction Value;
data pred; 
input Temperature_c Apparent_temperature__C_  B_MC B_OC B_PC IV1 IV2 IV3 IV4 IV5 IV6;
datalines; 
. 11.8056 0 0 0 129.817 7.8074 92.170 0.00 0 0
;

data new;
set pred weather_Test2;
run;

proc reg;
model Temperature_c = Apparent_temperature__C_  B_MC B_OC B_PC IV1 IV2 IV3 IV4 IV5 IV6/p clm cli alpha=0.05; 
run;

*VALIDATION TESTING;

Title"new y(temp) ";
data Nwether_456;
set Nwether_456;
if selected then new_temp = Temperature_c;
run;
PROC PRINT;
RUN;

title "Evaluating test set";
proc reg data=Nwether_456;
model  new_temp = Apparent_temperature__C_ Humidity Wind_Speed_km_h_ B_MC B_OC Clr MC PCld IV1 IV2 IV3 IV4 IV5 IV6;
output out = outm2(where=(new_temp=.)) p=yhat;

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





