% for the actual braille sensor, add a roller to the top/bottom with an
% encoder to ensure that the thing is tracked.

% prepare the data - looking only at where it changes removes the time/speed factor
diff = [];
for col = 1:length(raw)-1
    if any(raw(:,col) ~= raw(:,col+1))
        diff = [diff raw(:,col)];
    end
end

%% Top row
% reverse the order, so that signal 1 is the first contact
signal1 = diff(3,:);
signal2 = diff(2,:);
signal3 = diff(1,:);

[c12, lags12] = xcorr(signal2, signal1);
[~, I12] = max(abs(c12));
shift12 = lags12(I12);

[c23, lags23] = xcorr(signal3, signal2);
[~, I23] = max(abs(c23));
shift23 = lags23(I23);

% now we can shift the signals
len = length(signal1);  % assuming all signal lengths are the same
shifted_signal1 = signal1;
shifted_signal2 = zeros(1, len);
shifted_signal3 = zeros(1, len);

shift = mean([shift12, shift23]);

shifted_signal2(1:end-abs(shift)) = signal2(abs(shift)+1:end);

shifted_signal3(1:end-abs(2*shift)) = signal3(2*shift+1:end);

%{
signals =  [signal1;
            signal2;
            signal3;];

shifted_signals =  [zeros(1, len);
                    zeros(1, len);
                    signal3];

shift = mean([shift12, shift23]);

for signal_ind = 1:2
    for ind = 1:len+shift*signal_ind
        shifted_signal(signal_ind,ind) = signals(signal_ind,ind-shift*signal_ind);
    end
end
%}

%% Middle row
% suppose, signal1, signal2, and signal3 are your data vectors
signal8 = diff(12,:);
signal9 = diff(11,:);
signal10 = diff(10,:);
signal11 = diff(9,:);
signal12 = diff(8,:);

[c89, lags89] = xcorr(signal9, signal8);
[~, I89] = max(abs(c89));
shift89 = lags89(I89);

[c910, lags910] = xcorr(signal10, signal9);
[~, I910] = max(abs(c910));
shift910 = lags910(I910);

[c1011, lags1011] = xcorr(signal11, signal10);
[~, I1011] = max(abs(c1011));
shift1011 = lags1011(I1011);

[c1112, lags1112] = xcorr(signal12, signal11);
[~, I1112] = max(abs(c1112));
shift1112 = lags1112(I1112);

% now we can shift the signals
len = length(signal1);  % assuming all signal lengths are the same
shifted_signal8 = signal8;
shifted_signal9 = zeros(1, len);
shifted_signal10 = zeros(1, len);
shifted_signal11 = zeros(1, len);
shifted_signal12 = zeros(1, len);

shift = mode([shift89, shift910, shift1011, shift1112]);
shifted_signal9(1:end-abs(shift)) = signal9(shift+1:end);
shifted_signal10(1:end-abs(2*shift)) = signal10(2*shift+1:end);
shifted_signal11(1:end-abs(3*shift)) = signal11(3*shift+1:end);
shifted_signal12(1:end-abs(4*shift)) = signal12(4*shift+1:end);

%% Bottom row
% reverse the order, so that signal 1 is the first contact
signal17 = diff(19,:);
signal18 = diff(18,:);
signal19 = diff(17,:);

[c1718, lags1718] = xcorr(signal18, signal17);
[~, I1718] = max(abs(c1718));
shift1718 = lags1718(I1718);

[c1819, lags1819] = xcorr(signal19, signal18);
[~, I1819] = max(abs(c1819));
shift1819 = lags1819(I1819);

% now we can shift the signals
len = length(signal1);  % assuming all signal lengths are the same
shifted_signal17 = signal17;
shifted_signal18 = zeros(1, len);
shifted_signal19 = zeros(1, len);

shift = mean([shift1718, shift1819]);

shifted_signal18(1:end-abs(shift)) = signal18(abs(shift)+1:end);

shifted_signal19(1:end-abs(2*shift)) = signal19(2*shift+1:end);



shifted = [
shifted_signal1 0;
shifted_signal2 0;
shifted_signal3 0;
zeros(1, len) 0;
zeros(1, len) 0;
zeros(1, len) 0;
zeros(1, len) 0;
0 shifted_signal8;
0 shifted_signal9;
0 shifted_signal10;
0 shifted_signal11;
0 shifted_signal12;
zeros(1, len) 0;
zeros(1, len) 0;
zeros(1, len) 0;
zeros(1, len) 0;
shifted_signal17 0;
shifted_signal18 0;
shifted_signal19 0];

figure;
hold on;
plot(shifted(1,:)+4)
plot(shifted(2,:)+4)
plot(shifted(3,:)+4)
plot(shifted(8,:)+2)
plot(shifted(9,:)+2)
plot(shifted(10,:)+2)
plot(shifted(11,:)+2)
plot(shifted(12,:)+2)
plot(shifted(18,:))
plot(shifted(19,:))
plot(shifted(19,:))

figure
% make this like a "vote", then render as 1/n per vote
shifted_compressed = shifted([1 4 8 13 17],:);
% Plot matrix
imagesc(shifted_compressed)
% Color matrix
colormap([1 1 1; 0 0 0])
% Fix axis
axis square
axis equal
ylim([0 6])