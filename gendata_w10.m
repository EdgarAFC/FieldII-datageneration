clear all, close all, clc
% addpath('E:/Itamar_LIM/Field_II_ver_3_30_windows/')
addpath('/mnt/nfs/efernandez/Field_II_ver_3_30_linux/')

nsimus = 12500; %25000
possible_r = [2, 3, 4, 6, 8]/1000;
possible_c = 1420:10:1600;
possible_latpos = (-16:2:16)/1000;
possible_axpos = (40:2.5:70)/1000;

% savedir = 'E:/Itamar_LIM/datasets/simulatedCystDataset/raw_0.0Att_75angles/';
savedir = '/mnt/nfs/efernandez/datasets/data75PW/raw_0.0Att_75angles/';

file_path = ['/mnt/nfs/efernandez/Docs/' 'random_positions.h5'];
randpos_r = h5read(file_path, '/r');
randpos_c = h5read(file_path, '/c');
randpos_latpos = h5read(file_path, '/latpos');
randpos_axpos = h5read(file_path, '/axpos');

% randpos_r = uint8(randi(length(possible_r), 1, nsimus));
% randpos_c = uint8(randi(length(possible_c), 1, nsimus));
% randpos_latpos = uint8(randi(length(possible_latpos), 1, nsimus));
% randpos_axpos = uint8(randi(length(possible_axpos), 1, nsimus));
% 
% h5create([savedir 'random_positions.h5'], '/r', size(randpos_r))
% h5create([savedir 'random_positions.h5'], '/c', size(randpos_c))
% h5create([savedir 'random_positions.h5'], '/latpos', size(randpos_latpos))
% h5create([savedir 'random_positions.h5'], '/axpos', size(randpos_axpos))
% 
% h5write([savedir 'random_positions.h5'], '/r', randpos_r)
% h5write([savedir 'random_positions.h5'], '/c', randpos_c)
% h5write([savedir 'random_positions.h5'], '/latpos', randpos_latpos)
% h5write([savedir 'random_positions.h5'], '/axpos', randpos_axpos)

M = 12;
elapsed = 0;

%parpool('local');

parfor (idx_simu = 2001:2500,M)
    % Get phantom and cyst parameters
    r = possible_r(randpos_r(idx_simu));
    c = possible_c(randpos_c(idx_simu));
    lat_pos = possible_latpos(randpos_latpos(idx_simu));
    ax_pos = possible_axpos(randpos_axpos(idx_simu));

    % Verbose
    str_param = sprintf('simu%.5d_att_0.0_r_%.1f_c_%.1f_latpos_%.1f_axpos_%.1f', ...
                         idx_simu, r*1000, c,lat_pos*1000, ax_pos*1000);
    fprintf('%s\n', str_param)
    
    % Field simulation parameters
    field_init(-1)  
    fc  = 5.5e6;                    % Transducer center frequency [Hz]
    fs  = 22e6;                     % Sampling frequency [Hz]
    set_field('fs', fs);
    set_field('c', c);              % Speed of sound [m/s]
    set_field('show_times', 0);     % do not show calculation time
    
    % Transducer parameters
    height      = 7/1000;           % Height of element [m]
    width       = 0.24/1000;        % Width of element [m]
    kerf        = 0.06/1000;        % Distance between transducer elements [m]
    num_elem    = 128;              % Number of elements
    focus_rx    = [0 0 10000]/1000; % Electronic focus for rx transducer
    angles      = -16:32/(75-1):16;
    %angles      = 0;
    num_sub_x    = 1;
    num_sub_y    = 5;

    
    % Simulating phantom
    nscatters = 50000;
%     nscatters = 1000;
    [phantom_info] = phantom_lesion_cylindrical_cyst(idx_simu, nscatters, lat_pos, ax_pos, r);
    phantom_amplitudes = phantom_info.phantom_amplitudes;
    phantom_positions = phantom_info.phantom_positions;

    % Define impulse response and excitation
    impulse_response=sin(2*pi*fc*(0:1/fs:2/fc));
    impulse_response=impulse_response.*hanning(max(size(impulse_response)))';
    excitation=sin(2*pi*fc*(0:1/fs:2/fc));

    % Define Rx transducer and set impulse
    ThRx = xdc_linear_array (num_elem, width, height, kerf, num_sub_x, num_sub_y, focus_rx);
    xdc_impulse (ThRx, impulse_response);
    xdc_focus(ThRx, 0, focus_rx)
    rect = xdc_get(ThRx);
    ele_pos = unique(rect(24,:));

    % Scatters per angle
    signals = {};
    max_nsamples = 0;

    tx_focus_arr=zeros(length(angles),3);
    signals_cell={};
    time_zero_arr=zeros(1,length(angles));
    elapsed = 0;
  
    for idx_angle = 1:length(angles)
        start=tic;
        % Set angle and create rotated focus
        angle = angles(idx_angle);
        fprintf('\t%d)\t%s°\t\t', idx_angle, num2str(angle))
        focus_xz = [0; 10];
        ROTmatrix = [cosd(angle) sind(angle); -sind(angle) cosd(angle)];
        % ROTmatrix is [cos sin; -sin cos] instead of [cos -sin; sin cos]
        % because positive angles tilt to +x
        % and negative angles tilt to -x 
        foc_xz_rot = ROTmatrix*focus_xz;
        focus_tx = [foc_xz_rot(1) 0 foc_xz_rot(2)];

        % Set tx transducer with rotated focus
        ThTx = xdc_linear_array (num_elem, width, height, kerf, num_sub_x, num_sub_y, focus_tx);
        xdc_impulse(ThTx, impulse_response);
        xdc_excitation(ThTx, excitation);
        xdc_focus(ThTx, 0, focus_tx)

        % Compute scats
        [signals,time_zero]=calc_scat_multi(ThTx, ThRx, phantom_positions, phantom_amplitudes);
        xdc_free (ThTx)

        % Create array
        tx_focus_arr(idx_angle,:) = focus_tx;
        time_zero_arr(idx_angle) = time_zero;
        signals_cell{idx_angle} = signals;
        nsamples = size(signals,1);
        if nsamples>max_nsamples
            max_nsamples=nsamples;
        end

        Telapsed = toc(start);
        elapsed = elapsed + Telapsed;
        fprintf('\t\t%s seconds\n', num2str(Telapsed))

    end
    xdc_free(ThRx)
    field_end
    fprintf('Simulation %.5d is done\n', idx_simu)
    fprintf('%s seconds\n', num2str(elapsed))

    % Data structure to be saved
    fprintf('Creating data structures to be saved\n')
    signals_arr = zeros(max_nsamples, length(ele_pos), 1);
    for idx = 1:length(angles)
        signal = signals_cell{idx};
        nsamples = size(signal,1);
        signals_arr(1:nsamples,:,idx) = signal;
        signals_cell{idx}=nan; % releasing memory
    end

    % Saving info
    filename = [savedir str_param '.mat'];
    cell_var = {fc, fs,ele_pos, r, c, lat_pos, ax_pos, signals_arr, time_zero_arr, tx_focus_arr};
    %save(filename, 'cell_var')
    parsave(filename, cell_var)
    
end

function parsave(fname, cell_var)
  save(fname, 'cell_var')
end

% spmd
%     disp(numlabs)
% end
% disp(numlabs)