% Kunal Jathal

% Overlap and Add - Pitch Shifting
% =================================

% function OLA_PitchShift(input, windowSize, overlap, semitone)

% input         = input signal
% windowSize    = Window Size in samples
% overlap       = analysis overlap percentage (egs: for 50% overlap, enter 0.5)
% semitone      = number of semitones to shift up/down by. For egs, to shift up 2 semitones, enter 2. To shift down 1 semitone, enter -1.

function OLA_PitchShift(input, windowSize, overlap, semitone)

% Read in audio file
[inputSignal, fs] = wavread(input);

% Mono-fy it, just to circumvent MATLAB whining around matrix arithmetic
inputSignal = mean(inputSignal, 2);

% Play it
sound(inputSignal, fs);

% Create the Hann window to use
hannWindow = hann(windowSize);

% Use the number of semitones we want to pitch shift by to get the ratio
ratio = 2^(semitone/12);

% Get the synthesis overlap %. Again. I came up with this. True story.
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
outputSignal = zeros(ceil(numFrames * synthesisHopSize) + (windowSize - synthesisHopSize), 1);

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
    synthesisStartIndex = ((window - 1) * synthesisHopSize) + 1;
    synthesisEndIndex = synthesisStartIndex + windowSize - 1;
    outputSignal(synthesisStartIndex:synthesisEndIndex) = outputSignal(synthesisStartIndex:synthesisEndIndex) + analysisInputWindow;
end

% Now, let's resample the original signal at the pitch-shifted sample rate.
% To get integer values for the resample function, I'm just multiplying by
% a reasonably large factor, rounding, and then using that factor to divide
ratioNumerator = round(ratio * 10000);
newData = resample(outputSignal, 10000, ratioNumerator);

% Play it back at the *original* sample rate
sound(newData, fs);

end

