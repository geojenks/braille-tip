%% returns whether data1 peaks twice before data2 peaks

function [answer, timing] = peak_twice(data1, data2)
    % Extract time and values from data1 and data2
    t1 = data1{1}; y1 = data1{2};
    t2 = data2{1}; y2 = data2{2};

    % Find the timing of the peaks in each dataset
    peaks1 = sort(t1(find(diff([0; y1; 0])>0)));
    peaks2 = sort(t2(find(diff([0; y2; 0])>0)));
    % Find the timing of the peaks in each dataset
    troughs1 = sort(t1(find(diff([0; y1; 0])<0)));
    troughs2 = sort(t2(find(diff([0; y2; 0])<0)));
    
    % Check if data1 has two peaks before data2 has one
    if numel(peaks1) >= 2
        if numel(peaks2) >= 1
            if peaks1(2) < peaks2(1)
                answer = true;
                timing = [peaks1(1), peaks2(2), troughs1(1), troughs2(2)];
            else
                answer = false;
                timing = [peaks1(1) peaks2(1), troughs1(1) troughs2(1)];
            end
        else
            answer = true;
            timing = [peaks1(2), peaks2(2), troughs1(2), troughs2(2)];
        end
    elseif numel(peaks1) == 0
        answer = false;
        timing = 0;
    else
        answer = false;
        timing = [peaks1(1) peaks2(1) troughs1(1) troughs2(1)];
    end
end