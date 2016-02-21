clear all

%%
HOST = '192.168.7.2';
PORT = 54321;
N_BUFFER = 1;
MSG_SIZE = 936*1024;
BUFFER_SIZE = 160*1024;

% Preallocate raw data space
x = zeros(2*N_BUFFER*MSG_SIZE,1);

% Create TCP socket
sock = tcpip(HOST, PORT, 'NetworkRole', 'client');
set(sock, 'InputBufferSize', BUFFER_SIZE);
set(sock, 'TimeOut', 5);

% Connect to BeagleBone
fopen(sock);

% Send handshake
fwrite(sock, 'Ready');

% Get data
total = 0;
while total < 2*N_BUFFER*MSG_SIZE
    if total + BUFFER_SIZE/8 > 2*N_BUFFER*MSG_SIZE
        [temp, count] = fread(sock, 2*N_BUFFER*MSG_SIZE - total, 'uint8');
    else
        [temp, count] = fread(sock, BUFFER_SIZE/8, 'uint8');
    end
    x(total+1:total+count) = temp;
    total = total + count;
end

% Close connection
fclose(sock);

%%
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
mic1_signal = mic1_signal(2:end-100);
mic1_signal = 0.5*mic1_signal/max(mic1_signal);


% Unpack bit stream for mic 2
mic2_raw = zeros(size(x,1),4);
mic2_raw(:,1) = bitget(x,7);
mic2_raw(:,2) = bitget(x,5);
mic2_raw(:,3) = bitget(x,3);
mic2_raw(:,4) = bitget(x,1);

mic2_raw = mic2_raw';
mic2_raw = mic2_raw(:);

mic2_signal = resample(mic2_raw(1e6:end)-mean(mic2_raw(1e6:end)), 1, 50);
mic2_signal = mic2_signal(2:end-100);
mic2_signal = 0.5*mic2_signal/max(mic2_signal);


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
