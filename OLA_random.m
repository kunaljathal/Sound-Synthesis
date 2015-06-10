% Kunal Jathal

% Overlap and Add - Randomization
% ===============================

% function OLA_random(input, windowSize, overlap, ratio, random)

% input         = input signal
% windowSize    = Window Size in samples
% overlap       = analysis overlap percentage (egs: for 50% overlap, enter 0.5)
% ratio         = stretch ratio (egs to stretch the signal to 1.25 times its original length, enter 1.25)
% random        = the random deviation in samples. For example, to position windows +/- 100 samples from the usual hop start point, enter 100

function OLA_random(input, windowSize, overlap, ratio, random)

% Read in audio file
[inputSignal, fs] = wavread(input);

% Monofy it
inputSignal = mean(inputSignal, 2);

% Play it
sound(inputSignal, fs);

% Create the Hann window to use
hannWindow = hann(windowSize);

% Get the synthesis overlap %
synthesis = overlap + (1 - ratio);

% The synthesis percentage has to be over 0% and below 100%.
if (synthesis <= 0 || synthesis >= 1)
    error('The synthesis percentage has to be over 0% and below 100%. Try adjusting the overlap percentage or the ratio.');
end

% Get the hop sizes
analysisHopSize = windowSize - round((windowSize * overlap));
synthesisHopSize = windowSize - round((windowSize * synthesis));

% We now need to window the signal as per the hann window size
numFrames = ceil(length(inputSignal)/analysisHopSize);

% Get the final output signal ready
outputSignal = zeros(ceil(numFrames * (synthesisHopSize + random)) + (windowSize - synthesisHopSize + random), 1);

for window = 1:numFrames
    % Analysis Section 
    analysisStartIndex = ((window - 1) * analysisHopSize) + 1;
    analysisEndIndex = analysisStartIndex + windowSize - 1;

    % If we are at the last window, zero pad the original signal so we can
    % multiply it by Hann window
    if (analysisEndIndex > length(inputSignal))
        numZeroes = windowSize - (length(inputSignal) - analysisStartIndex) - 1;        
        analysisInputBlock = [inputSignal(analysisStartIndex:length(inputSignal)); zeros(numZeroes, 1)];
    else
        analysisInputBlock = inputSignal(analysisStartIndex:analysisEndIndex);        
    end
    
    analysisInputWindow = analysisInputBlock .* hannWindow;

    % Synthesis Section

    % Add randomization here. Note that we don't want to shift the first window, only windows after it.        
    if (window == 1)
        randomSize = 0; 
    else        
        % The random size we add is basically a margin of deviation. For
        % example, if the user inputs 20 (samples), we generate a random
        % number between -20 and 20 and move the window either forward or
        % backward around the hop start point (synthesisStartIndex).
        randomSize = round((0 - random) + (2 * random).* rand(1));
    end
    
    synthesisStartIndex = ((window - 1) * synthesisHopSize) + 1 + randomSize;
    synthesisEndIndex = synthesisStartIndex + windowSize - 1;
    outputSignal(synthesisStartIndex:synthesisEndIndex) = outputSignal(synthesisStartIndex:synthesisEndIndex) + analysisInputWindow;
end

% Play back the final sound
sound(outputSignal, fs);

end
