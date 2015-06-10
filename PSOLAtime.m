% Kunal Jathal

% PSOLA - Time Modification
% =========================

% function PSOLAtime(input, windowSize, overlap, timeRatio, semitone)

% input                 = input signal
% analysisWindowSize    = Window Size in samples
% analysisOverlap       = analysis overlap percentage (egs: for 50% overlap, enter 0.5)
% ratio                 = stretch ratio in time (egs to stretch the signal to 1.25 times its original length, enter 1.25
%                                                    to compress the signal to 0.85 times it's original length, enter 0.85)

function PSOLAtime(input, analysisWindowSize, analysisOverlap, ratio)

% Read in the audio file
[inputSignal, fs] = wavread(input);

% Mono-fy it, just to circumvent MATLAB whining about matrix arithmetic
inputSignal = mean(inputSignal, 2);

% Play it
sound(inputSignal, fs);


%% Analysis and Synthesis Section

% Create the Hann window to use when windowing for analysis during PSOLA
hannWindow = hann(analysisWindowSize);

% Get the analysis hop size
analysisHopSize = analysisWindowSize - round((analysisOverlap * analysisWindowSize));

% Get the synthesis overlap %
synthesisOverlap = analysisOverlap + (1 - ratio);

% Get the synthesis overlap percentage in SAMPLES
synthesisOverlapSize = round(synthesisOverlap * analysisWindowSize);

% The synthesis percentage has to be over 0% and below 100%.
if (synthesisOverlap <= 0 || synthesisOverlap >= 1)
    error('The synthesis percentage has to be over 0% and below 100%. Try adjusting the overlap percentage or the ratio.');
end


%% Fundamental Frequency Computation per Frame & OLA

% Because we need to perform fundamental frequency computation (as part of
% PSOLA), we will split the signal up into FRAMES, and calculate the
% fundamental frequency of each FRAME. We will then use this fundamental
% frequency to gauge the correct amount of overlap to use for all the OLA
% windows within that frame.

frameSize = round(fs/4);
numberOfFrames = ceil(length(inputSignal)/frameSize);
frameStartIndex = 1;
analysisStartIndex = 1;
synthesisStartIndex = 1;
outputSignal = [];

% Let's go through the process, window by window. We will compute the
% fundamental frequency per FRAME.

for frameIndex=1:numberOfFrames
    frameEndIndex = frameStartIndex + frameSize - 1;

    % If the last frame extends past the input signal, shorten it to the
    % end of the signal for the purposes of pitch computation
    if (frameEndIndex > length(inputSignal))
        frameEndIndex = length(inputSignal);
    end
        
    % Get the fundamental frequency of the current frame (using chroma) and 
    % hence the pitch period in SAMPLES (of the current frame)    
    fundFreq = chroma(inputSignal(frameStartIndex:frameEndIndex), fs);
    pitchPeriod = round((1/fundFreq) * fs);

    % Ensure that the synthesis overlap size is the closest multiple of the
    % pitch period
    desiredOverlap = round(synthesisOverlapSize/pitchPeriod) * pitchPeriod;

    % Calculate the synthesis hop size based on the desired overlap
    synthesisHopSize = analysisWindowSize - desiredOverlap;

    % Now that we have all the analysis and synthesis variables ready,
    % let's do the overlapping and adding.
    
    while (analysisStartIndex < frameEndIndex)        
        analysisEndIndex = analysisStartIndex + analysisWindowSize - 1;
        
        % If we are at the last window, zero pad the original signal so we can
        % multiply it by the Hann window (since the sizes need to be equal)
        if (analysisEndIndex > length(inputSignal))
            numZeroes = analysisWindowSize - (length(inputSignal) - analysisStartIndex) - 1;        
            analysisInputBlock = [inputSignal(analysisStartIndex:length(inputSignal)); zeros(numZeroes, 1)];
        else
            %If we aren't at the last window, no need to pad
            analysisInputBlock = inputSignal(analysisStartIndex:analysisEndIndex);        
        end
    
        % Window it!
        analysisInputWindow = analysisInputBlock .* hannWindow;
        
        % Synthesis Section    
        synthesisEndIndex = synthesisStartIndex + analysisWindowSize - 1;

        % Build the output
        outputSignal = [outputSignal; zeros((synthesisEndIndex - synthesisStartIndex + 1), 1)];
        outputSignal(synthesisStartIndex:synthesisEndIndex) = outputSignal(synthesisStartIndex:synthesisEndIndex) + analysisInputWindow;
        
        % Update to the next analysis window
        analysisStartIndex = analysisStartIndex + analysisHopSize;
        synthesisStartIndex = synthesisStartIndex + synthesisHopSize;
    end
    
    % Update to the next frame
    frameStartIndex = frameStartIndex + frameSize;
end


% Let's play the final signal!
sound(outputSignal, fs);

end