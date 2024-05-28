clc
clear
close all

% dir_list = dir('C:\TESIS\DATOS_TESIS2\raw_0.0Att_75angles\simulaciones');
dir_list = dir('/mnt/nfs/efernandez/datasets/data75PW/raw_0.0Att_75angles/');

first_id = 1;
for i = 1004:2003
 
    file_name = dir_list(i).name;
    folder_name = dir_list(i).folder;
    cell=load(strcat(folder_name,'/',file_name));

    fc=cell.cell_var{1,1};
    fs=cell.cell_var{1,2};
    ele_pos=cell.cell_var{1,3};
    r=cell.cell_var{1,4};
    c=cell.cell_var{1,5};
    lat_pos=cell.cell_var{1,6};
    ax_pos=cell.cell_var{1,7};
    signal=cell.cell_var{1,8};
    time_zero=cell.cell_var{1,9};
    %tx_focus_arr=cell.cell_var{1,10};

    idx = str2double(file_name(5:9));
    % saving info
%     savedir = 'C:\TESIS\DATOS_TESIS2\';
    savedir = '/mnt/nfs/efernandez/datasets/data75PW/';
%     str_param = sprintf('simu%.5d_r_%.1f_c_%.1f_latpos_%.1f_axpos_%.1f', ...
%                         idx, r*1000, c,lat_pos*1000, ax_pos*1000);
    simu_counter = sprintf('/simu%.5d', idx);

    if first_id == 1
        fprintf('GOING FROM simu%.5d\n', idx);
    end
    first_id = 0;

    filename = [savedir 'simus_01001-02000.h5'];
    
    h5create(filename, [simu_counter '/fc'], size(fc))
    h5create(filename, [simu_counter '/fs'], size(fs))
    h5create(filename, [simu_counter '/r'], size(r))
    h5create(filename, [simu_counter '/c'], size(c))
    h5create(filename, [simu_counter '/ele_pos'], size(ele_pos))
    h5create(filename, [simu_counter '/lat_pos'], size(lat_pos))
    h5create(filename, [simu_counter '/ax_pos'], size(ax_pos))
    h5create(filename, [simu_counter '/signal'], size(signal))
    h5create(filename, [simu_counter '/time_zero'], size(time_zero))

    %%%%%%%%%%%%%%%% write %%%%%%%%%%%%%%%%
    h5write(filename, [simu_counter '/fc'], fc)
    h5write(filename, [simu_counter '/fs'], fs)
    h5write(filename, [simu_counter '/r'], r)
    h5write(filename, [simu_counter '/c'], c)
    h5write(filename, [simu_counter '/ele_pos'], ele_pos)
    h5write(filename, [simu_counter '/lat_pos'], lat_pos)
    h5write(filename, [simu_counter '/ax_pos'], ax_pos)
    h5write(filename, [simu_counter '/signal'], signal)
    h5write(filename, [simu_counter '/time_zero'], time_zero)
end

fprintf('UNTIL simu%.5d\n', idx);
fprintf('DONE\n')
