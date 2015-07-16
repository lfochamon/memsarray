% Load data from file
fid = fopen('buff');
x = fread(fid, inf, 'ubit8');
fclose(fid);

% Fix Linux endianess
for i = 1:4:length(x)
    x(i:i+3) = flipud(x(i:i+3));
end


% Unpack bit stream for mic 1
mic1_raw = zeros(size(x,1),4);
mic1_raw(:,1) = bitget(x,8);
mic1_raw(:,2) = bitget(x,6);
mic1_raw(:,3) = bitget(x,4);
mic1_raw(:,4) = bitget(x,2);

mic1_raw = mic1_raw';
mic1_raw = mic1_raw(:);

mic1_signal = resample(mic1_raw(1e6:end)-mean(mic1_raw(1e6:end)), 1, 50);
mic1_signal = 0.5*mic1_signal/max(mic1_signal);
mic1_signal = mic1_signal(2:end-100);


% Unpack bit stream for mic 2
mic2_raw = zeros(size(x,1),4);
mic2_raw(:,1) = bitget(x,7);
mic2_raw(:,2) = bitget(x,5);
mic2_raw(:,3) = bitget(x,3);
mic2_raw(:,4) = bitget(x,1);

mic2_raw = mic2_raw';
mic2_raw = mic2_raw(:);

mic2_signal = resample(mic2_raw(1e6:end)-mean(mic2_raw(1e6:end)), 1, 50);
mic2_signal = 0.5*mic2_signal/max(mic2_signal);
mic2_signal = mic2_signal(2:end-100);


% Plot and play audio for mic 1
figure();
plot(mic1_signal);
grid;

player = audioplayer(mic1_signal, 40e3);
playblocking(player);


% Plot and play audio for mic 2
figure();
plot(mic2_signal);
grid;

player = audioplayer(mic2_signal, 40e3);
playblocking(player);
