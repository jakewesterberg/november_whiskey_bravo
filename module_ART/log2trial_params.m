clear all;

%% load log
datapath = 'C:\Users\grinten\Documents\Data\Mr Nilson\StimV1_exp1_2023\20230605';
log_file = 'TheLastNilsonV1StimRun_B7_15h14m_05062023';%'TheLastNilsonV1StimRun_B4_11h37m_01062023';%'20230412_B001';
log_path = [datapath,'/',log_file,'.mat'];
log = load(log_path);

%%
allPara = log.allPara;
allPara = [allPara; log.allValidTrialFlag; string(log.allerrorcodestr); log.allMicroStimFlag];

var_names = ["visual_or_estim", "RF_x", "RF_y", "RFsize", "microPreStimT", "microStimT", "microPostStimT",... 
"instanceID", "channelID_128", "stimulatorID", "stimulatorChannel", "freq", "currentLevel", "numPulses", "phaseWidth", ...
"interphase", "stimulatorHW_ID", "backgroundLum", "CondID", "ValidTrialFlag", "errorCodeString", "microStimFlag"];

%%
params = array2table(allPara, "RowNames",var_names);
writetable(params, 'trial_params_B7.csv','WriteRowNames',true)