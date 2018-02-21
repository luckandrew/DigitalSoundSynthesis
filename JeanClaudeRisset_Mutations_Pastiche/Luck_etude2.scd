// Attribution:
//
// [1] Partial Gains
//
// Listed partial gains from Dodge and Jerse's Computer Music, Second Edition on page 105 fig 4.28
// Bell is from Jean Claude Risset's Mutations
//
// Risset's Bells
//
// Partial No.2	Frequency Ratio3	Magnitude (in dB)4	Duration Scale	Partial Name
// 0	0.56	0.0	1.0	Hum
// 1	0.56 (+1)	-3.5	0.9	Hum (beating)
// 2	0.92	0.0	0.65	Prime
// 3	0.92 (+1.7)	5.1	0.55	Prime (beating)
// 4	1.19	8.5	0.325	Tierce
// 5	1.7	4.5	0.35
// 6	2.0	3.3	0.25	Nominal
// 7	2.74	2.5	0.2	(Undeciem)
// 8	3.0	2.5	0.15	Superquint
// 9	3.76	0.0	0.1
// 10	4.07	2.5	0.075	Octave Nominal


/////////////////////////////etude 2//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

(

//////////////// DEFINE VARIABLES ////////////////

//am bell vars
var note1, note2, amBellsynthDef, score;
var tableSize, buffer;
var carrierPartialGains, amPartialGains;

//additive prism bell vars
var addSynthDef;
var additiveFunc;
var partialGains, partialRatios, partialDurs, partialOffsets, partialData, partialStartOffsets;

// helper functions
var sinCosPanLaw;

// vars for NRT output
var outputPath, headerFormat, sampleFormat, sampleRate, numOutputChannels;

////vars for Bel melodies////
var freqArray, bellMelsynthDef, numEvents, bellMelpartialData, additiveFunc2;

/////////////// SET VARIABLE VALUES ///////////////

// set the NRT vars here...
outputPath = "~/Desktop/testCTK.wav"; // output file path
headerFormat = "WAV";                 // soundfile header format
sampleFormat = "int24";               // soundfile sample format
sampleRate = 44100;                   // sample rate
numOutputChannels = 2;                // stereo --> 2 channels

// create a score
score = CtkScore.new;

/////////////// DEFINE SYNTH HELPER FUNCTIONS ///////////////

// sine-cosine panning law coefficient function
// angle argument in degrees
sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

///////////////// DEFINE SYNTHS //////////////////


/////////////////////////////AM Bell Synth Def/////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

amBellsynthDef = CtkSynthDef.new(\myAMSynth, {arg dur, gain, ris = 0.1, dec = 0.1, carFreq = 440.0, modFreq = 440.0, modIndexGain = 0.0,  panAngle = 0.0, buffer = 0;

    // variables
    var bus = 0;      // var to specify output bus: first output
    var carOsc, modOsc;  // oscillators
    var out;          // output!
    var amp;          // a few vars for synthesis
    var ampEnv;       // var for envelope signal
    var normFac;      // normalization factor
    var modIndex;     // modulation index (a scalar)

    // calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale
    modIndex = modIndexGain.dbamp; // convert " "
    normFac = (1 + (2*modIndex)).reciprocal; // amplitude normalization factor

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
		        Env.new([0.0000001, 1, -90.dbamp], [0.5, 1, 0], \exp),
        timeScale: dur
    );

    modOsc = SinOsc.ar(modFreq, 0, amp * (2*modIndex)); // simple modulator (single sinusoid)
    carOsc = Osc.ar(buffer, carFreq, 0, amp + modOsc);  // complex carrier (multiple sinusoids)
    carOsc = normFac * carOsc;  // normalize carrier oscillator

    // apply the amplitude envelope
    carOsc = ampEnv * carOsc;

    // expand to two channels - panning
    out = sinCosPanLaw.value(-45.rand2(45)) * carOsc;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)
});


/////////////////////////////Additive Bell Synth Def/////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////


addSynthDef = CtkSynthDef.new(\mySinOscSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, panAngle = 0.0;

    // variables
    var bus;          // var to specify output bus
    var osc, out;     // vars assigned to audio signals
    var amp, phase;  // a few vars for synthesis
    var ampEnv, env;       // vars for envelope signal
	var curve, level;

    // assign values
    bus = 0;          // first output
    phase = 0;        // phase of oscillator

    // calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale

    // the amplitude envelope
    //env = Env.linen(ris, 1.0 - (ris + dec), dec);
	env = Env.new([1, -90.dbamp], [1], \exp);

    // the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(env, timeScale: dur);


    // the oscillator
    osc = SinOsc.ar(freq, phase, amp);

    // rescale osc, by multiplying by ampEnv
    osc = ampEnv * osc;

    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * osc;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)
});

/////////////////////////////Bell Melody Synth Def/////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

bellMelsynthDef = CtkSynthDef.new(\mySinOscSynth, {arg dur, gain = -12, ris = 0.1, dec = 0.1, freq = 440.0, panAngle = 0;
	var env, envGen, amp, pitchEnv;

	amp = gain.dbamp;

	env = Env.perc; // env define within bellMelsynthDef
	envGen = EnvGen.kr(env, timeScale: dur);
	amp = envGen * amp;

	Out.ar(0,
		// 'amp' is a value between 0 and 1.
		SinOsc.ar(freq, 0, amp) * sinCosPanLaw.value(panAngle)
	)
});

///////additiveFunc

additiveFunc2 = {arg start, dur, gain = -12, ris = 0.1, dec = 0.1, freq = 880.0, bellMelpartialData; // pass in values

	// iterate through the bellMelpartialData array to generate individual notes to add to the score
	bellMelpartialData.do({arg thisPartialData, i;
		var thisPartialDur;
		var thisPartialFreq;
		var thisPartialGain;
		var thisPartialRatio;

		// retreive partial dur, gain and ratio
		thisPartialDur = thisPartialData.at(0);
		thisPartialGain = thisPartialData.at(1);
		thisPartialRatio = thisPartialData.at(2);

		thisPartialDur = dur * thisPartialDur; // scale partial dur by dur argument
		thisPartialGain = gain + thisPartialGain; // add gains
		thisPartialFreq = freq * thisPartialRatio; // multiply freq by index (harmonic series!)

		// create a note for each partial...
		score.add(
			bellMelsynthDef.note(start, thisPartialDur)
			.dur_(thisPartialDur)
			.gain_(thisPartialGain)
			.ris_(ris)
			.dec_(dec)
			.freq_(thisPartialFreq)
			.panAngle_(-45.rrand(45));
		);
	})
};


///////////////// SET PARAMETER VALUES //////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////



///////////////// AM Bell Parameters ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

// score parameters
tableSize = 2.pow(13);           // for the wavetable

amPartialGains = Harmonics.new(3);
carrierPartialGains = amPartialGains.rand(-3.5, 8.5);  //generate first three harmonics from 4b


///////////////// Additive Parameters ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////


// score parameters for Risset's Bell
partialGains = [ 0, -3.5, 0.0, 5.1, 8.5, 4.5, 3.3, 2.5, 2.5, 0.0, 2.5 ];
partialRatios = [ 0.56, 1.56, 0.92, 2.62, 1.19, 1.7, 2.0, 2.74, 3.0, 3.76, 4.07 ];
partialDurs = [ 1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075 ];
partialOffsets = [ 0, 1, 0, 1.7, 0, 0, 0, 0, 0, 0, 0 ];
// partialStartOffsets = Array.geom(11, 0.1, 0.99).reverse;
partialStartOffsets = Array.series(11, 0, 0.05);

// group partial durs, gains and ratios into a new array
// NOTE: we could write the following four lines as a function!
partialData = [partialDurs, partialGains, partialRatios, partialOffsets, partialStartOffsets];
partialData = partialData.flop; // invert rows and columns

///////////////// CREATE BUFFERS //////////////////

// create the wavetable buffer for carrier - MUST be wavetable format:
buffer = CtkBuffer.buffer(tableSize).sine1(time: 0.0, normalize: 1, wavetable: 1, clear: 1, args: carrierPartialGains.dbamp);

///////////////// Bell Melody Partials//////////////////

// group partial durs, gains and ratios into a new array
bellMelpartialData = [partialDurs, partialGains, partialRatios];
bellMelpartialData = bellMelpartialData.lace; // interlace the values
bellMelpartialData = bellMelpartialData.reshape((bellMelpartialData.size/3).asInteger, 3); // regroup values

//number of Bell Melody events
numEvents = 6;

// evaluate the additive synthesis function
// args: start, dur, amp, ris, dec, freq, bellMelpartialData
// this function adds individual partials to the score to be played

numEvents.do{arg inc, i;
	var numNotes = 10.rrand(40), startOffset = inc * 1.rrand(3);
	numNotes.floor.do{arg inc1;
		additiveFunc2.value(
			(0.01.rrand(0.1) * inc1 + i
			) + startOffset + 4, // start time
			2.0 + i, // duration
			-32, // amp
			0.5 + i*3, // ris
			10, //dec
			(90 * (inc1 + 1 + inc)).rrand(100 * (inc1 + 1 + inc)), // fundamental frequency
			bellMelpartialData,
			panAngle: -45.rand2(45)
		);
	};
};

///////////////// CREATE SYNTH NOTE CALLS //////////////////


note1 = amBellsynthDef.note(starttime: 0.0, duration: 20).dur_(20.0).gain_(0.0).carFreq_(202.4).modFreq_(1161.776).modIndexGain_(18.0).buffer_(buffer);

note2 = amBellsynthDef.note(starttime: 10.0, duration: 20).dur_(20.0).gain_(0.0).carFreq_(202.4).modFreq_(1161.776).modIndexGain_(18.0).buffer_(buffer);


/////////////////////////////AM Bell Score/////////////////////////////////////////////////////

// add the buffer (wavetable) to the score
score.add(buffer);

// add notes to score
score.add(note1);
score.add(note2);


/////////////////////////////Additive Bell Score////////////////////////////////////////////////


// function to add individual notes to our score for additive synthesis
additiveFunc = {arg start, dur, gain = -12.0, ris = 0.1, dec = 0.1, freq = 440.0, partialData; // pass in values

    // iterate through the partialData array to generate individual notes to add to the score
    partialData.do({arg thisPartialData, i;
        var thisPartialDur;
        var thisPartialFreq;
        var thisPartialNote;

        var thisPartialGain;
        var thisPartialRatio;
		var thisPartialOffset;
		var thisPartialStartOffset;

        // retreive partial dur, gain and ratio
        thisPartialDur = thisPartialData.at(0);
        thisPartialGain = thisPartialData.at(1);
        thisPartialRatio = thisPartialData.at(2);
		thisPartialOffset = thisPartialData.at(3);
		thisPartialStartOffset = thisPartialData.at(4);

        thisPartialDur = dur * thisPartialDur; // scale partial dur by dur argument
        thisPartialGain = gain + thisPartialGain; // scale partialGain by gain
		thisPartialFreq = (freq * thisPartialRatio); // multiply freq by ratio, e.g., not necessarily harmonic!
        thisPartialFreq = thisPartialOffset + thisPartialFreq;

        // create a note for each partial...
        thisPartialNote = addSynthDef.note(
            starttime: start + thisPartialStartOffset, duration: thisPartialDur
        )
        .dur_(thisPartialDur)
        .gain_(thisPartialGain)
        .ris_(ris)
        .dec_(dec)
        .freq_(thisPartialFreq);

        // then and add note for each partial to the score
        score.add(thisPartialNote);
    })
};

///////////////// EVALUATE FUNCTIONS //////////////////

// evaluate the additive synthesis function
// args: start, dur, gain, ris, dec, freq, partialData
// this function adds individual partials to the score to be played

additiveFunc.value(
    start: 0.0,
    dur: 20.0,
    gain: -20.0,
    ris: 0.001,
    dec: 0.005,
    freq: 440.0,
    partialData: partialData
);


///////////////// RENDER THE SCORE //////////////////

// write score to sound file with the -write message
score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

SFPlayer("~/Desktop/testCTK.wav".standardizePath).gui