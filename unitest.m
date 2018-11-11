clc
clear all
close all

%% Test Aircraft Initialization
ac = aircraft.Aircraft('A320');

%% Creating a EMWET Worker and Running
% p = parpool('local',1);
spmd
    tic;
%     list_dir = dir('temp\EMWET');
%     worker_list = zeros(length(list_dir), 1);
%     
%     labindex
% 
%     for i=1:length(list_dir)
%         result = str2double(list_dir(i).name);
%         if isnan(result)
%             result = 0;
%         end
%         worker_list(i) = result;
%     end

    current_worker = labindex;

    current_path = [pwd '\temp\EMWET\' num2str(current_worker)];
    mkdir(current_path)

    % Copying EMWET to New Worker Directory
    copyfile([pwd '\bin\EMWET.p'], current_path)

    toc;
end

% delete(p);

    
