//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
/*
Author: Andrew Luck
DXArts :: Digital Synthesis 461A :: Winter 2018
Last Update: Jan 16, 2018
*/
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////Solution 1/////////////////////////////////////


(
var myRandomValue = rand(9); //sets random number value between 0 and 9
[1,2,3,4,5].do({arg object, index; //begin iteration
	object.post;  //posts value of index object
	" plus ".post;
	myRandomValue.post; //posts myRandomValue
	" is ".post;
	(object + myRandomValue).post; //does addition of object value + random number
	" \n".postln;  //two line breaks
});
)


///////////////////////////////////Solution 2/////////////////////////////////////


//Solution 2

(
[1,2,3,4,5].do({arg object, index; //begin iteration
	var myRandomValue = rand(9); //sets random number value between 0 and 9
	object.post;  //posts value of index object
	" plus ".post;
	myRandomValue.post; //posts random value generated on this iteration
	" is ".post;
	(object + myRandomValue).post; //does addition of object value + random number
	" \n".postln;  //two line breaks
});
)

///////////////////////////////////Solution 3/////////////////////////////////////


(
a = Array.fill(10); //initializes array with a size of 10
a.do({arg object, index; //begin iteration
	var myRandomValue = rand(100); //sets random number value between 0 and 100
	a[index] = myRandomValue;  //sets current index value to myRandomValue
});
)

///////////////////////////////////Solution 4/////////////////////////////////////


(
a = Array.fill(10); //initializes array with a size of 10
a.do({arg object, index; //begin iteration
	var myRandomValue = rand(100); //sets random number value between 0 and 100
	a[index] = myRandomValue;  //sets current index value to myRandomValue
}).sort({ arg a, b; a > b }); //sorts in reverse order
)


///////////////////////////////////Solution 5a/////////////////////////////////////


(
var calcHarmonicFreqs;
calcHarmonicFreqs = { arg frequency , numHarms;
    frequency * Array.series(numHarms, 1) //generates series with steps of 1
}; //first arg is frequency, second is number of harmonics


calcHarmonicFreqs.value(frequency: 440, numHarms: 10);
calcHarmonicFreqs.value(frequency: 432, numHarms: 5); // crystal healing magic frequencies lulz
)


///////////////////////////////////Solution 5b/////////////////////////////////////


//Function Def

(
var calcFreqs;
 calcFreqs = { arg frequency, numDivisions, interval, numHarms;
	var newBaseFreq;
	newBaseFreq = frequency * (2.pow(interval/numDivisions));
	newBaseFreq * Array.series(numHarms, 1)
};

//Execute with Args

calcFreqs.value(440.0, 12.0, 3.0, 5.0);
)




///////////////////////////////////Extra Credit/////////////////////////////////////

(
///////////////// DEFINE VARIABLES /////////////////

var synthDef, freqs, calcFreqs, dur, score;

// vars for NRT output
var    outputPath, headerFormat, sampleFormat, numOutputChannels, sampleRate;

/////////////// SET VARIABLE VALUES ///////////////

// set the NRT vars here...
outputPath = "~/Desktop/testCTK.wav"; // output file path
headerFormat = "WAV";                 // soundfile header format
sampleFormat = "int24";               // soundfile sample format
sampleRate = 44100;                   // sample rate
numOutputChannels = 2;                // stereo --> 2 channels

// a score
score = CtkScore.new;

////////////////// DEFINE SYNTHS //////////////////

// CtkSynthDef assigned to var called 'synthDef'
synthDef = CtkSynthDef.new(\mySinOscSynth, {arg freq;

    // variables
    var bus;          // var to specify output bus
    var osc, out;     // vars assigned to audio signals
    var gain, amp, phase;  // a few vars for synthesis

    // assign values
    bus = 0;          // first output
    phase = 0;        // phase of oscillator
    gain = -12.0;     // gain of oscillator

    // calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale

    // the oscillator
    osc = SinOsc.ar( // SinOsc UGen
        freq,        // 1st arg of SinOsc: freq (from synthDef argument)
        phase,       // 2nd arg of SinOsc: (set to a default value)
        amp          // 3rd arg of SinOsc: (set to a default value)
    );

    // expand to two channels
    out = [osc, osc];

    // out!!
    Out.ar(         // Out UGen
        bus,        // 1st arg of Out: (set to a default value - the 1st output)
        out         // 2nd arg of Out: (two channels)
    )
});

///////////////// GENERATE FREQ ARRAY //////////////////


calcFreqs = { arg frequency, numDivisions, interval, numHarms;
	var newBaseFreq;
	newBaseFreq = frequency * (2.pow(interval/numDivisions));
	newBaseFreq * Array.series(numHarms, 1)
};

freqs = calcFreqs.value(220.0, 12.0, 3.0, 5.0);


///////////////// SET PARAMETER VALUES //////////////////

// scoring parameters
dur = 2.0;

///////////////// POPULATE THE SCORE //////////////////

// construct score - iterate through the freq array
freqs.do({arg thisFreq, i;
    score.add(synthDef.note(starttime: 0.1, duration: dur).freq_(thisFreq)); // starttime, duration, freq
});

//score.play;

///////////////// RENDER THE SCORE //////////////////

// write score to sound file with the -write message
// NOTE: we're using argument names to specify the args. For 'duration', we're letting Ctk
//       do the work for us!
score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

SFPlayer("~/Desktop/testCTK.wav".standardizePath).gui;


