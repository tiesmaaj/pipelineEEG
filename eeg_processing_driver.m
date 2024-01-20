function eeg_processing_driver(base_path, excelfile_name)
% entry point for eeg processing
% update the file paths and the corresponding nframes if doing it manually
% to automate, vhdr files must be in a subdirectory of current directory
% the save_files directories don't need to exist, they will be created

%% NEXT THING TO DO:
%  
% Assuming files are linked to their new names, go in and use
% those.
% At the scanner, start naming files according to participant
% number and scan number! vcon02-run01-ecr.*
% (but I will manually change the others for now.)
% For the fmri scans, may need to start a spreadsheet, like the one
% we had at nih. Yes, start entering these, and then we can
% directly read from the excel sheet.
%
% also note that figure names will overwrite each other if multiple
% scans, need to adjust their filenames
% and on figure 900, bands are not written properly

tic; % start timer

%%addpath(genpath("./chronux"))
%addpath(genpath('~/matlab/chronux_2_12/'))
%addpath /Users/changce/Desktop/scripts/eeg_scripts_updated
%addpath ~/matlab/eeglab14_1_2b


% PROCESS IS COMPLETELY AUTOMATED! (delete manual entry soon - lines 35-58)
global CHECK_BAD_CHANNELS DISP
CHECK_BAD_CHANNELS = 0; % 1 to manually check bad channels, 0 to automate
DISP = 1; % 1 to create and save figures, else 0

% 1 to manually enter file paths and nframes, 0 to automate
manually_enter_file_info = 0;
if manually_enter_file_info
   
    % data that come out of BVA
    preproc_base_path = 'C:/Users/Eric/Desktop/eegfmri_vu/eeg_preproc/vcon02/scan01/';
    % folder to write the processed data
    proc_base_path = 'C:/Users/Eric/Desktop/eegfmri_vu/eeg_proc/vcon02/scan01/';
       
    % add all unprocessed vhdr files to the array
    %eeg_files = [preproc_base_path + "ecr_run1_575frames_cbc.vhdr"]
    eeg_files = preproc_base_path + "ecr_run1_575frames_cbc.vhdr";
    %  [preproc_base_path + "run3_ecr_cbc.vhdr"
    %             preproc_base_path + "run2_ecr_cbc.vhdr"];


    % add all processed .mat file save locations to array
    % directories will be created if they don't exist
    save_prefix = "vcon02-scan01.mat";
    save_files = [proc_base_path + save_prefix];
    %  [proc_base_path + "1_26_21_sc\run3_ecr\run3_ecr.mat"
    %              proc_base_path + "1_29_21_st\run2_ecr\run2_ecr.mat"];
            
else
 
    % read excelsheet to table
    T = readtable(excelfile_name);
    
    % cnt: index of scans in the spreadsheet labled 'fmri'
    cnt=1;
    for i=1:height(T)
        isFmri = strcmp(T.Var3(i), 'fmri');
        if (isFmri && contains(T.Var11(i), '.vhdr'))
            disp(cnt);
            
            % populate RAW and PROC file paths
            [eeg_files{cnt}, save_files{cnt}] = get_files(T.Var11(i));
            
            % find nframes in excelsheet
            scans_to_do.nframes{cnt} = T.Var8(i);
            
            % change save file to 'prettier' name (vconXX-scanXX.mat)
            subject_num = extractBetween(save_files{cnt}, '/PROC', '/eeg_ml');
            scan_num = T.Var13(i);
            
            disp("Scan Number: ");
            disp(scan_num);
            
            % construct save file paths (scans_to_do.files)
            tmp = split(save_files{cnt}, '/eeg_ml');
            tmp = split(save_files{cnt}, tmp{2});
            scans_to_do.files{cnt} = strcat(tmp{1}, subject_num{1}, '-', scan_num{1}, '.mat');
            
            cnt = cnt+1;
        end
    end
end


scans_to_do.orig_files = eeg_files;

%defaults
%nframes=575;
chans_use = {'P3','P4','Pz','O1','O2','Oz'};
slices_per_TR = 30;
TR = 2.1;
bad_channels = [];

% do the truncations on all of the vhdr files
% also saves list of buffer overflow frames, if they exist
for i=1:length(eeg_files)
    OUT = preproc_eeg_postBVA(scans_to_do.orig_files{i}, scans_to_do.files{i}, scans_to_do.nframes{i});
end


% do regressions on all of the .mat files we got from truncation
%OUT2 = regressor_loop_updated(scans_to_do);
OUT2 = regressor_loop_updated_eric(scans_to_do, chans_use, slices_per_TR,... 
                                    TR, bad_channels);

% create a ppt with the figure pictures for each subject
if DISP
    make_powerpoints(save_files);
end

t = toc;
disp([newline, 'Processing complete: total time = ', num2str(t), ' seconds']);

function [eeg_files, save_files] = get_files(vhdr_name)
% altered for virtual desktop: enter RAW folder to save time, then use dir()
% original solution was dir(base_path + "**/*" + vhdr_name)
% where base_path is a parameter to get_files()
cd /
cd /data1/neurdylab/datasets/eegfmri_vu/RAW/
cbc_vhdr_files = dir("**/*" + vhdr_name);

cbc_vhdr_files = cbc_vhdr_files(~cellfun('isempty', {cbc_vhdr_files.date})); 

for i=1:length(cbc_vhdr_files)
    eeg_files(i) = cbc_vhdr_files(i).folder + "/" + cbc_vhdr_files(i).name;
    
    % virtual desktop change
    tmp = strrep(cbc_vhdr_files(i).folder, "RAW", "PROC");
    save_fp = strrep(tmp, "eeg_BVA", "eeg_ml");
    save_fn = extractBetween(cbc_vhdr_files(i).name, "", "_cbc") + ".mat";
    save_files(i) = save_fp + "/" + save_fn;
end

% As it stands, this function is never called
function make_powerpoints(save_files)
import mlreportgen.ppt.*

for i=1:length(save_files)
    disp(newline + "Making powerpoint for subject #" + i + "...")
    
    [save_path, ~, ~] = fileparts(save_files(i));
    ppt = Presentation(save_path + "\figures.pptx");
    
    fig1 = Picture(save_path + "\fig_200.png");
    fig1.Height = '6.5in';
    fig1.Width = '5.11in';
    fig1.X = '-0.25in';
    fig1.Y = '0.25in';

    fig2 = Picture(save_path + "\fig_400.png");
    fig2.Height = '5.84in';
    fig2.Width = '5.01in';
    fig2.X = '4.51in';
    fig2.Y = '0.91in';

    fig3 = Picture(save_path + "\fig_900.png");
    fig3.Height = '5.45in';
    fig3.Width = '4.7in';
    fig3.X = '8.94in';
    fig3.Y = '1.15in';

    picture_slide = add(ppt,'Blank');

    add(picture_slide, fig1);
    add(picture_slide, fig2);
    add(picture_slide, fig3);

    close(ppt);
end
