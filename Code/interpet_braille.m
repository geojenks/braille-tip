%% Code to process raw data from the Braille-tip to accompany the paper
% Braille-tip: Structured Small-Footprint Tactile Sensor for High Acuity
% Dynamic Tactile Tasks
% George P Jenkinson, Andrew T Conn, Antonia Tzemanaki
%
% signature 
% Author: G.Jenkinson
% E-Mail: george.jenkinson.2018@bristol.ac.uk
% Date: Jan 2024
%
% For demonstrations linked in paper, load "data-n" or "data-text" and run
% interpret_braille(braille_data), i.e.:
%
% load('data-n.mat')
% interpet_braille(braille_data);
%
% or
%
% load('data-text.mat')
% interpet_braille(braille_data);

% braille is time series data made up of time and data columns for each
% sensory channel
function [letters, binary, binaries] = interpet_braille(braille, prev_letters, recursion)

%% Initialise
if ~exist('prev_letters','var')
 % third parameter does not exist, so default it to something
  prev_letters = "";
end

if ~exist('recursion','var')
 % third parameter does not exist, so default it to something
  recursion = 0;
else
  recursion = recursion + 1;
end


% uncomment to plot truncated data at each recursion
figure;
j = [4 5 6 9 10 11 14 15 16];
for i = 1:9
subplot(9,1,i);
plot(braille{1,j(i)}, braille{2,j(i)});
end
%}

threshold = 0.4;
time = cell(1,19);
data = cell(1,19);

% indices of Brailletip rows used
row1 = [4 5 6];
row2 = [9 10 11];
row3 = [14 15 16];

% indices of Brailletip columns used
col1 = [4 9 14];
col2 = [5 10 15];
col3 = [6 11 16];

%for chan = 1:19
for chan = [4, 5, 6, 9, 10, 11, 14, 15, 16]
    time{chan} = braille{1,chan};
    datum = braille{2,chan};
    % normalise data
    datum = datum-min(datum);
    datum = datum/max(datum);
    % Apply threshold to data (make it binary)
    data{chan} = datum>threshold;

end


% uncomment to plot truncated binary data at each recursion
figure;
j = [4 5 6 9 10 11 14 15 16];
for i = 1:9
subplot(9,1,i);
plot(time{j(i)}, data{j(i)});
end
%}

%% Find times of next peaks in data

% tim is a 4 x 2 array of the form:
% time of first peak col1        time of last peak col2      time of first trough col1     time of last trough col2
% time of first peak col2        time of last peak col3      time of first trough col2     time of last trough col3
%
% where 1, 2, 3 refer to the row

tim1 = zeros([2,4]);
tim2 = zeros([2,4]);
tim3 = zeros([2,4]);

for column = [1,2]
    [first_both(column), tim1(column,:)]  = peak_twice({time{row1(column)},data{row1(column)}},{time{row1(column+1)},data{row1(column+1)}});
    [second_both(column), tim2(column,:)] = peak_twice({time{row2(column)},data{row2(column)}},{time{row2(column+1)},data{row2(column+1)}});
    [third_both(column), tim3(column,:)]  = peak_twice({time{row3(column)},data{row3(column)}},{time{row3(column+1)},data{row3(column+1)}});
end

binary = [-1 -1;-1 -1;-1 -1];

if tim1 == zeros([2,4]);
    binary(1,:) = [0 0];
end
if tim2 == zeros([2,4]);
    binary(2,:) = [0 0];
end
if tim3 == zeros([2,4]);
    binary(3,:) = [0 0];
end

% cutoff is the time at which data will be cut to look at the next letter
cutoff = 0;

%% Logic: is row empty (any dots are from the next letter)?
% if it starts after any other row has finished, then yes
if tim1(1,1) > tim2(2,4) || tim1(1,1) > tim3(2,4)
    %then row 1 is empty
    binary(1,:) = [0 0];
end
if tim2(1,1) > tim1(2,4) || tim2(1,1) > tim3(2,4)
    %then row 2 is empty
    binary(2,:) = [0 0];
end
if tim3(1,1) > tim2(2,4) || tim3(1,1) > tim1(2,4)
    %then row 2 is empty
    binary(3,:) = [0 0];
end

%% Logic: does the column have 2 dots?
if tim1(1,2) ~= tim1(2,1)
    % if it is another letter, it stays at 0
    binary(1,:) = -1.*binary(1,:);
    cutoff = max(cutoff, any(binary(1,:))*tim1(2,4));
end
if tim2(1,2) ~= tim2(2,1)
    binary(2,:) = -1.*binary(2,:);
    cutoff = max(cutoff, any(binary(2,:))*tim2(2,4));
end
if tim3(1,2) ~= tim3(2,1)
    binary(3,:) = -1.*binary(3,:);
    cutoff = max(cutoff, any(binary(3,:))*tim3(2,4));
end

%% Logic: does row have single dot in its own column?
% does another dot end before this one starts?
if sum(binary(1,:)) ~= 2
    if tim1(1,1) > tim2(1,3) || tim1(1,1) > tim3(1,3)
        %it is in 2nd column
        %binary(1,:).*  is to only count if it has not already been
        %set to 0 in a previous step
        binary(1,:) = binary(1,:).*[0 -1];
        cutoff = max(cutoff, any(binary(1,:))*tim1(2,4));
    elseif ((binary (2,2)~=0) &&  (tim1(1,3) < tim2(1,1))) || ((binary (3,2)~=0) &&  (tim1(1,3) < tim3(1,1)))
        %it is in 1st column
        binary(1,:) = binary(1,:).*[-1 0];
        cutoff = max(cutoff, any(binary(1,:))*tim1(2,4));
    end
end
if sum(binary(2,:)) ~= 2
    if tim2(1,1) > tim1(1,3) || tim2(1,1) > tim3(1,3)
        %it is in 2nd column
        binary(2,:) = binary(2,:).*[0 -1];
        cutoff = max(cutoff, any(binary(2,:))*tim2(2,4));
    %elseif tim2(1,3) > tim1(1,1) || tim2(1,3) > tim3(1,1)
    elseif ((binary (1,2)~=0) &&  (tim2(1,3) < tim1(1,1))) || ((binary (3,2)~=0) &&  (tim2(1,3) < tim3(1,1)))
        %it is in 1st column
        binary(2,:) = binary(2,:).*[-1 0];
        cutoff = max(cutoff, any(binary(2,:))*tim2(2,4));
    end
end
if sum(binary(3,:)) ~= 2
    if tim3(1,1) > tim2(1,3) || tim3(1,1) > tim1(1,3)
        %it is in 2nd column
        binary(3,:) = binary(3,:).*[0 -1];
        cutoff = max(cutoff, any(binary(3,:))*tim3(2,4));
    %elseif tim2(1,3) > tim3(1,1) || tim1(1,3) > tim3(1,1)
    elseif ((binary (1,2)~=0) &&  (tim3(1,3) < tim1(1,1))) || ((binary (2,2)~=0) &&  (tim3(1,3) < tim2(1,1)))
        %it is in 1st column
        binary(3,:) = binary(3,:).*[-1 0];
        cutoff = max(cutoff, any(binary(3,:))*tim3(2,4));
    end
end

%% Braille dictionary

braille_dict{bin2dec('100000')} = 'a';
braille_dict{bin2dec('110000')} = 'b';
braille_dict{bin2dec('100100')} = 'c';
braille_dict{bin2dec('100110')} = 'd';
braille_dict{bin2dec('100010')} = 'e';
braille_dict{bin2dec('110100')} = 'f';
braille_dict{bin2dec('110110')} = 'g';
braille_dict{bin2dec('110010')} = 'h';
braille_dict{bin2dec('010100')} = 'i';
braille_dict{bin2dec('010110')} = 'j';
braille_dict{bin2dec('101000')} = 'k';
braille_dict{bin2dec('111000')} = 'l';
braille_dict{bin2dec('101100')} = 'm';
braille_dict{bin2dec('101110')} = 'n';
braille_dict{bin2dec('101010')} = 'o';
braille_dict{bin2dec('111100')} = 'p';
braille_dict{bin2dec('111110')} = 'q';
braille_dict{bin2dec('111010')} = 'r';
braille_dict{bin2dec('011100')} = 's';
braille_dict{bin2dec('011110')} = 't';
braille_dict{bin2dec('101001')} = 'u';
braille_dict{bin2dec('111001')} = 'v';
braille_dict{bin2dec('010111')} = 'w';
braille_dict{bin2dec('101101')} = 'x';
braille_dict{bin2dec('101111')} = 'y';
braille_dict{bin2dec('101011')} = 'z';

%% Process binary into letter
if strjoin(string(binary(:))) == "0 0 0 0 0 0"
    letters = '';
else
    letters = braille_dict{bin2dec(strjoin(string(binary(:))))};
end

% split the data at the start of the next letter
for i = 1:3
    braille{1,col1(i)} = time{col1(i)}(time{col1(i)}>cutoff);
    braille{2,col1(i)} = data{col1(i)}(time{col1(i)}>cutoff);
    braille{1,col2(i)} = time{col2(i)}(time{col2(i)}>cutoff);
    braille{2,col2(i)} = data{col2(i)}(time{col2(i)}>cutoff);
    braille{1,col3(i)} = time{col3(i)}(time{col3(i)}>cutoff);
    braille{2,col3(i)} = data{col3(i)}(time{col3(i)}>cutoff);
end

disp(letters)
% if end of word/string, end recursion, print letters, and read aloud
if strjoin(string(binary(:))) == "0 0 0 0 0 0"
    disp(prev_letters+letters)
    % subsidiary (made by another author) function to read text aloud
    addpath('text2speech')
    tts(prev_letters+letters)
    letters = prev_letters+letters;
    binaries = [2 ;2 ;2];
    return
else
    % recurse
    [letters, ~, binaries] = interpet_braille(braille, prev_letters+letters, recursion);
    binaries = [binary [2 ; 2 ;2] binaries];
end

%% plot if at initial level of recursion
if recursion == 0
    figure
    [y, x] = find(binaries==1);
    scatter(x, y, 500, 'filled', 'blue')
    hold on
    [y2, x2] = find(binaries==0);
    scatter(x2, y2, 500, 'blue')
    axis square
    axis equal
    xlim([0 max(max(x), max(x2)) + 1])
    ylim([0 4])
    set(gca, 'YDir','reverse')
end
end