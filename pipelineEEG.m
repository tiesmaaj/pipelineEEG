%% EEGLab Preprocessing Pipeline 
% Adam Tiesman - 1/20/24
clear all
close all
clc

% Add path to your EEGLab folder and run eeglab
addpath('/Users/a.tiesman/Documents/Research/pipelineEEG/eeglab2023.1')
eeglab

% Load your raw EEG data files (should have 3 different file types)
eeg_filepath = 'G:/My Drive/Research/Brainhack2024/vcon30-scan01_ecr.eeg';
vhdr_filepath = 'G:/My Drive/Research/Brainhack2024/vcon30-scan01_ecr.vhdr';
vmrk_filepath = 'G:/My Drive/Research/Brainhack2024/vcon30-scan01_ecr.vmrk';
load(eeg_filepath); load(vhdr_filepath); load(vmrk_filepath);

% Preprocessing driver used, entry point for raw EEG data 
eeg_processing_driver(base_path, excelfile_name)