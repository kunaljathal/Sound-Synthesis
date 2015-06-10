% Kunal Jathal

% Overlap and Add - Fixed
% =======================

% function OLA(input, windowSize, overlap, ratio)

% input         = input signal
% windowSize    = Window Size in samples
% overlap       = analysis overlap percentage (egs: for 50% overlap, enter 0.5)
% ratio         = stretch ratio (egs to stretch the signal to 1.25 times its original length, enter 1.25)

function OLA(input, windowSize, overlap, ratio)

% Read in the audio file
[inputSignal, fs] = wavread(input);

% Mono-fy it, just to circumvent MATLAB whining around matrix arithmetic
inputSignal = mean(inputSignal, 2);

% Play it
sound(inputSignal, fs);

% Create the Hann window to use
hannWindow = hann(windowSize);

% Get the synthesis overlap %. I came up with this formula. Seriously.
synthesis = overlap + (1 - ratio);

% The synthesis percentage has to be over 0% and below 100%.
if (synthesis <= 0 || synthesis >= 1)
    error('The synthesis percentage has to be over 0% and below 100%. Try adjusting the overlap percentage or the ratio.');
end

% Get the hop sizes
analysisHopSize = windowSize - round((windowSize * overlap));
synthesisHopSize = windowSize - round((windowSize * synthesis));

% We now need to window the signal as per the hann window size
% Interesting tid-bit: for the longest time I was dividing my inputSignal
% by the windowSize to get the number of windows, and obviously that wasn't
% working. Finally it hit me. 
numFrames = ceil(length(inputSignal)/analysisHopSize);

% Get the final output signal ready. The size of this is governed by the
% synthesisHopSize as well as the little extra portion that isn't
% overlapped at the end by another window.
outputSignal = zeros(ceil(numFrames * synthesisHopSize) + (windowSize - synthesisHopSize), 1);

% Let's go through the process, frame by frame (i.e. window by window)
for window = 1:numFrames
    % Analysis Section 
    analysisStartIndex = ((window - 1) * analysisHopSize) + 1;
    analysisEndIndex = analysisStartIndex + windowSize - 1;

    % If we are at the last window, zero pad the original signal so we can
    % multiply it by the Hann window (since the sizes need to be equal)
    if (analysisEndIndex > length(inputSignal))
        numZeroes = windowSize - (length(inputSignal) - analysisStartIndex) - 1;        
        analysisInputBlock = [inputSignal(analysisStartIndex:length(inputSignal)); zeros(numZeroes, 1)];
    else
        %If we aren't at the last window, no need to pad
        analysisInputBlock = inputSignal(analysisStartIndex:analysisEndIndex);        
    end

    % Window it!
    analysisInputWindow = analysisInputBlock .* hannWindow;

    % Synthesis Section    
    synthesisStartIndex = ((window - 1) * synthesisHopSize) + 1;
    synthesisEndIndex = synthesisStartIndex + windowSize - 1;
    
    % Build the output
    outputSignal(synthesisStartIndex:synthesisEndIndex) = outputSignal(synthesisStartIndex:synthesisEndIndex) + analysisInputWindow;
end

% Let's play the final signal!
sound(outputSignal, fs);

end
