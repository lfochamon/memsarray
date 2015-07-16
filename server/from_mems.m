% Load data from file
fid = fopen('buff');
x = fread(fid, inf, 'ubit8');
fclose(fid);

% Fix Linux endianess
for i = 1:4:length(x)
    x(i:i+3) = flipud(x(i:i+3));
end

% Get bitstream
mic1_raw = [];
for b = 8:-1:1
    mic1_raw = [mic1_raw , bitget(x,b)];
end

mic1_raw = mic1_raw';
mic1_raw = mic1_raw(:);

% Decimate and normalize bit stream
mic1_signal = resample(mic1_raw(1e6:end)-mean(mic1_raw(1e6:end)), 1, 50);
mic1_signal = 0.7*mic1_signal/max(mic1_signal);
mic1_signal = mic1_signal(2:end-100);

% Plot audio output
figure();
plot(mic1_signal);

% Play data
player = audioplayer(mic1_signal, 40e3);
play(player);