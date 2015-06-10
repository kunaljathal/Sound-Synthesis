% Kunal Jathal

% PSOLA - Pitch Modification
% ==========================

% function PSOLApitch(input, analysisWindowSize, analysisOverlap, semitone)

% input                 = input signal
% analysisWindowSize    = Window Size in samples
% analysisOverlap       = analysis overlap percentage (egs: for 50% overlap, enter 0.5)
% semitone              = number of semitones to shift up/down by. For egs, to shift up 2 semitones, enter 2. To shift down 1 semitone, enter -1.

function PSOLApitch(input, analysisWindowSize, analysisOverlap, semitone)

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

% Use the number of semitones we want to pitch shift by to get the ratio
ratio = 2^(semitone/12);

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


% Now, let's resample the original signal at the pitch-shifted sample rate.
% To get integer values for the resample function, I'm just multiplying by
% a reasonably large factor, rounding, and then using that factor to divide
ratioNumerator = round(ratio * 10000);
newData = resample(outputSignal, 10000, ratioNumerator);

% Play it back at the *original* sample rate
sound(newData, fs);


end