%reading a sound file ampling it by 'Fs' rate into 'original' array
FrameNum = 123;
window=0;
[original, Fs] = audioread('a.wav');
fprintf('Fs is %d\n', Fs);

%'Fs' sample in each frame so 'N' sample in 0.025 seconds
N = 0.025 * Fs;
fprintf('N is %d\n', N);


%'M' is shift length
M = 0.4 * N;
fprintf('M is %d\n', M);
%calculating how many frame we have with 'N' length and 'M' shift
NumOfFrames = floor((length(original)-(N-M))/M) + 1;
FramedY = zeros(N, NumOfFrames);
for i = 1:NumOfFrames - 1
    os = ((i - 1) * M) + 1;
    FramedY(:,i) = original(os : os + N - 1);
end

%the last frame is not full and we fill it with zeros
FramedY(1:(length(original) - (i * M)),i+1) = original(((i * M) + 1):length(original));

%choose which windowing
if window == 1
    wind = rectwin(N);
else
    wind = hamming(N);
end

%windowing each frame by multiply each voice signal value with
%corresponding window value
WindowedY = zeros(N, NumOfFrames);
for k = 1:NumOfFrames
    WindowedY(:,k) = FramedY(:,k) .* wind;
end

%Preemphasis
alpha = 0.9;
for k = 1:NumOfFrames
    for j = 2:N
        WindowedY(j,k) = WindowedY(j,k) - (alpha * WindowedY(j - 1,k));
    end
end

%this part is for calculating vakdar frames
%after that we will find pitch freq on a random frame
for k = 1:NumOfFrames
    DC = 0;
    %calculating DC value by finde the mean of signal
    
    for c = 1:N
            DC = DC + WindowedY(c,k);
    end
    DC = DC / N;
   
    %set DC to zero
    ZeroOffsetWindowedY(:,k) = WindowedY(:,k) - DC;
end

%calculating energy of each frame
temp = ZeroOffsetWindowedY .* ZeroOffsetWindowedY;
energy = sum(temp)/N;

%range variable specify how many frame of start and end of file you think are zero
range = 4;
ESilence = (sum(energy(1:range))+sum(energy(length(energy) - range + 1:length(energy))))/(range*2);

%choose threshhold to remove silence part of signal
%we choose it uphand by multiply by 3
SilenceThresh = 2.5 * ESilence;



%fast fourie transform on windowed signal
WindowedYFreq = fft(WindowedY);

%logarithm of absolout of fast fourie of windowed signal
Logabs = log(abs(WindowedYFreq));

%reverse fast foure on the last value for getting cepstrom
%cepstrom = fft() --> Log(abs()) --> ifft()
%we need real part of it in order to show it
cepstrom=real(ifft(Logabs));

%in order to get putch frequency we need to get high time cepstrom
High_time_cepstrom = zeros(size(cepstrom(:,1),1)/2, NumOfFrames);
%we yse 20 for threshold
for k1 = 1:NumOfFrames
    mul = 0;
    for k2 = 1:(size(cepstrom(:,k1),1)/2)
        if (k2 == 20)
            mul = 1;
        end
        High_time_cepstrom(k2,k1) = cepstrom(k2,k1) .* mul;
    end
end

%for frame number 100
%we finde the picks location
[a, b] = findpeaks(High_time_cepstrom(:,FrameNum));
[I1,I2] = max(a);

x = [1:200];
x = Fs./x;

%converting to hz from sample
pitch = Fs./b(I2);

subplot(5, 1, 1);
plot(original);
TitleStr = sprintf('Original Audio Time Signal');
title(TitleStr);

subplot(5, 1, 2);
plot(WindowedY(:,FrameNum));
TitleStr = sprintf('Frame number %d in Hamming', FrameNum);
title(TitleStr);

subplot(5, 1, 3);
plot(abs(WindowedYFreq(:,FrameNum)));
TitleStr = sprintf('Fast Fourie Transform of %d frame', FrameNum);
title(TitleStr);

subplot(5, 1, 4);
plot(cepstrom(2:400,FrameNum));
TitleStr = sprintf('Log absoulote of %d ftame fft or Cepstrom', FrameNum);
title(TitleStr);

subplot(5, 1, 5);
plot(High_time_cepstrom(1:200,FrameNum));
TitleStr = sprintf('High Time Cepstrom of frame %d', FrameNum);
title(TitleStr);

fprintf("Pitch frequency = %f khz\n",pitch);

set(gcf, 'Position', get(0, 'Screensize'));