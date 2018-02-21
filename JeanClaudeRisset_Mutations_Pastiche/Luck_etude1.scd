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

(
var score, synthDef;
var additiveFunc;
var partialGains = [1.0, 0.67, 1.0, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1.0, 1.33].ampdb; // gains for Risset Bell
var partialRatios = [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2.0, 2.74, 3.0, 3.76, 4.07]; // ratios for each partial
var partialDurs = [1.0, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075]; // duration scaling;
var partialData, noteArray, rhythmArray, noteArray3, noteSeed, rhythmArray3;
var sec1Func, sec2Func, sec3Func;
var	outputPath, headerFormat, sampleFormat, numOutputChannels, sampleRate;
var sinCosPanLaw;
var prismFunc, prismArray, prismSeed;

// vars for PBells
var synthDefPBells, pBfreqs, bellDur, pBellenv, pBpitchEnv, pBfreqsList, pBnumNotes, pBdensityEnv, bellDurArray;

// vars for AM Kicks

var synthDef2;
var noteParams, start, dur, gain;
var noteCarFreqs, noteQs, noteModIndxs;
var noteParamsFunc;
var numNotes;
var qToNoiFreqFunc;

// vars for AM Bells

var note1, amBellsynthDef;
var tableSize, buffer;
var carrierPartialGains;

// set the NRT vars here...
outputPath = "~/Desktop/testCTK.wav"; // output file path
headerFormat = "WAV";                 // soundfile header format
sampleFormat = "int24";               // soundfile sample format
numOutputChannels = 2;                // stereo --> 2 channels
sampleRate = 44100;

// sine-cosine panning law coefficient function
// angle argument in degrees
sinCosPanLaw = { arg angleInDegrees = 0;
	var angleInRadians;
	var theta;

	angleInRadians = angleInDegrees/180*pi;

	theta = pi/4 - angleInRadians;

	[theta.cos, theta.sin]
};

///////////Bell Prism Synth Def//////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

//thisThread.randSeed = 1502;
synthDef = CtkSynthDef.new(\mySinOscSynth2, {arg dur, gain = -12, freq = 440.0, ris = 0.1, panAngle;
	var env, envGen, amp;
	env = EnvGen.kr(Env([0, 1, 0], [ris, dur - ris], [4, -4])); // env define within synthDef
	amp = env * gain.dbamp * 0.7;
	Out.ar(0,
		SinOsc.ar(freq, 0, amp * sinCosPanLaw.value(panAngle))

	)
});

///////////PBells Synth Def//////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////


// CtkSynthDef assigned to var called 'synthDefPBells'
synthDefPBells = CtkSynthDef.new(\mySinOscSynth, {arg freq, panAngle;

    // variables
    var bus;          // var to specify output bus
    var osc, out;     // vars assigned to audio signals
    var gain, amp, phase;  // a few vars for synthesis

    // assign values
    bus = 0;          // first output
    phase = 0;        // phase of oscillator
    gain = -24.0;     // gain of oscillator

    	// amplitude envelope
	pBellenv = EnvGen.kr(Env([0.000001, 1, 1, 0.000001], [0, 2, 3, 0.00001], \exp));

	// calcs
    amp = pBellenv * gain.dbamp;  // convert from gain in dB to linear amplitude scale

	//pitch envelope

	pBpitchEnv = EnvGen.kr(Env([0.5, 1, 1], [0.05, 1.5, 2], \exp));

    // pBpitchEnv = 1;

	freq = pBpitchEnv * freq;

    // the oscillator
    osc = SinOsc.ar( // SinOsc UGen
        freq,        // 1st arg of SinOsc: freq (from synthDefPBells argument)
        phase,       // 2nd arg of SinOsc: (set to a default value)
        amp          // 3rd arg of SinOsc: (set to a default value)
    );

    // expand to two channels
//    out = [osc, osc];

	 out = sinCosPanLaw.value(panAngle) * osc;  // <-- Panning happens here!

    // out!!
    Out.ar(         // Out UGen
        bus,        // 1st arg of Out: (set to a default value - the 1st output)
        out         // 2nd arg of Out: (two channels)
    )
});

// function to add individual notes to our score for additive synthesis
additiveFunc = {arg start, dur, gain = -12, ris, freq, partialData, panAngle; // pass in values

	// iterate through the partialData array to generate individual notes to add to the score
	partialData.do({arg thisPartialData, i;
		var thisPartialDur;
		var thisPartialFreq;
		var thisPartialGain;
		var thisPartialRatio;
		var thisPartialStart;

		// retreive partial dur, gain and ratio
		thisPartialDur = thisPartialData.at(0);
		thisPartialGain = thisPartialData.at(1);
		thisPartialRatio = thisPartialData.at(2);


		thisPartialDur = dur * thisPartialDur; // scale partial dur by dur argument
		thisPartialGain = gain + thisPartialGain; // add gains together
		thisPartialFreq = freq * thisPartialRatio; // multiply freq by index (harmonic series!)

		if (i == 1, //test value 1, if it is second harmonic
			{ thisPartialFreq = thisPartialFreq + 1 }, // function 1

			{if ( i == 3, //test value 2, if it is fourth harmonic
				{ thisPartialFreq = thisPartialFreq + 1.7} // function 2
			)
			}
		);

		// then and add note for each partial to the score
		score.add(
			synthDef.note(start, thisPartialDur)
			.dur_(thisPartialDur)
			.gain_(thisPartialGain)
			.freq_(thisPartialFreq)
			.ris_(ris)
			.panAngle_(panAngle)
		);

	})
};


///////////AM Kick Synth Def////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////


synthDef2 = CtkSynthDef.new(\myAMBLNSynth, {arg dur, gain, ris = 0.1, dec = 0.1, carFreq = 440.0, noiFreq = 440.0, modIndexGain = 0.0,  panAngle = 0.0;

    // variables
    var bus = 0;      // var to specify output bus: first output
    var noise, carOsc;
    var out;          // output!
    var amp;          // a few vars for synthesis
    var modIndex;
    var normFac;
    var ampEnv;       // var for envelope signal
	var pitchEnv;
	var carFreq0, carFreq1, noiFreq0, noiFreq1;

	// bad practice.... hardcoded below... just for testing!!
	carFreq0 = carFreq;
	carFreq1 = 2.pow(-4) * carFreq;
	noiFreq0 = noiFreq;
	noiFreq1 = 2.pow(-4) * noiFreq;


    // initial calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale
    modIndex = modIndexGain.dbamp;
    normFac = (1 + (2*modIndex)).reciprocal; // amplitude normalization factor

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
		        Env.new([1, 1, 0.00001], [dur/2], \exp),
        timeScale: dur
    );

	carFreq =  EnvGen.kr(
		Env.new([carFreq0, carFreq1], [dur/2], 'exp'),
		timeScale: dur
	);
	noiFreq =  EnvGen.kr(
		Env.new([noiFreq0, noiFreq1], [dur/2], 'exp'),
		timeScale: dur
	);


    noise = LFNoise1.ar(noiFreq, amp * (2*modIndex));  // (linear interpolation sample-and-hold noise)
    carOsc = SinOsc.ar(carFreq, 0.01, amp + noise);       // simple carrier (single sinusoid)
    carOsc = normFac * carOsc;                         // normalize carrier oscillator

    // apply the amplitude envelope and Ring Modulate
    carOsc = ampEnv * carOsc;



    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * carOsc;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)
});

// create a score
// the additiveFunc Function will assume a variable named 'score' has been defined.
score = CtkScore.new;

// group partial durs, gains and ratios into a new array
partialData = [partialDurs, partialGains, partialRatios].flop;
"partialData is: ".post;
partialData.postln;


///////////AM Bell Parameters///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

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
    out = sinCosPanLaw.value(panAngle) * carOsc;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)
});



///////////BellPrism Parameters/////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

prismArray = Array.series(partialGains.size, 0, 0.1);  //start times
// create my note array with rhythms, a random duration and a random amp
noteArray3 = prismArray.size.collect{arg i;
	[prismArray[i], 5, -24];
};
"prismArray is: ".post;
prismArray.postln;


///////////PBells Parameters/////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////


// scoring parameters
bellDur = 3;
// bellDurArray = Array.geom(10, 1, 0.5).reverse;

pBfreqsList = ([0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2.0, 2.74, 3.0, 3.76, 4.07] * 440).scramble;

pBfreqs = [pBfreqsList.at(1), pBfreqsList.at(2)];

///////////AMKick Parameters///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

// function to calculate fn for a desired q
qToNoiFreqFunc = {arg carFreq, q;
    carFreq/(2*q);
};

// vary index of modulation --> noisy-ness, Q is constant
//
numNotes = 12;
start = 15.81;
dur = 0.48;
gain = -12;
noteCarFreqs = Array.fill(numNotes, { 660.0 });
noteQs = Array.fill(numNotes, { 0.5 });
// noteModIndxs = Array.series(numNotes, -9 * (numNotes-1), 9); // <--- This is our "data of interest"
noteModIndxs = Array.fill(numNotes, -18);

// -------------------------------------------
// use -collect (iteration!) to pack into array, noteParams
noteParams = numNotes.collect({arg i;
    Array.with(start + (i * dur), dur, gain, noteCarFreqs.at(i), noteQs.at(i), noteModIndxs.at(i))
});


///////////AMBell Parameters///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

// score parameters
tableSize = 2.pow(13);           // for the wavetable
// carrierPartialGains = [0.0, -6.0, -9.0]; // gains for 1st three harmonics in dB
// See above, Attribution [1]
// carrierPartialGains = [ 0, -36, -1 ];  // gains for 1st three harmonics in dB
// // See above, Attribution [2]
// carrierPartialGains = [ -18, 0, -19 ];  // gains for 1st three harmonics in dB

partialGains = Harmonics.new(3);
carrierPartialGains = partialGains.rand(-3.5, 8.5);  //generate first three harmonics from 4b

// CREATE BUFFER

// create the wavetable buffer for carrier - MUST be wavetable format:
buffer = CtkBuffer.buffer(tableSize).sine1(time: 0.0, normalize: 1, wavetable: 1, clear: 1, args: carrierPartialGains.dbamp);

///////////BellPrism Function////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

prismFunc = {arg start, prismArray, prismSeed, partialData; // arguments are start time and a note array [start times, durs, amps]
	noteArray3.do{arg note, i; //iterate over that array
		var numHarms, harmArray, partialArray, noteDur, noteStart, noteGain;
		noteStart = note[0]; // unpack note start time
		noteDur = note[1]; // unpack note duration
		noteGain = note[2]; // unpack note gain
		numHarms = 10; // 5 harmonics
		harmArray = Array.series(numHarms, 0, 1); // fill Array with partial numbers
		"harmArray is: ".post;
		harmArray.value.postln;
		// collect into a new array the partial data only at subset harmonics
		partialArray = harmArray.collect{arg index;
			partialData[index];
			"partialData[index] is: ".post;
			partialData[index].postln;
		};
		"partialArray is: ".post;
		partialArray.postln;

		//prismSeed = prismSeed * 5.rrand(1);  // chooses to multiple 1-5 for the first freqency of the prism to begin
		prismSeed = prismSeed * (i+1);  // chooses to multiple 1-5 for the first freqency of the prism to begin
		"prismSeed is: ".post;
		prismSeed.postln;


		additiveFunc.value(
			start + noteStart,  // start time and offset note start time
			noteDur, // note duration
			noteGain,  // note gain
			0.1, // 0.5 //noteDur/3,  // attack time
			prismSeed, // the fundamental frequency of our prism
			partialArray, // our new partialData array with a subset of partials
			/*45.rand2(-45); //envelope for the panning*/
			0,
		);
	};
};

//////////////PBells Score//////////////////////////////////////////////////////////////
//////////////PBells Score//////////////////////////////////////////////////////////////

// pBdensityEnv  = EnvGen.kr(Env([0.000001, 1, 1, 0.000001], [0, 2, 3, 0.00001], \exp));

pBnumNotes = 1;

//play 10 notes using our SynthDef.

	pBnumNotes.do{arg item;
	var freqRand;
	freqRand = pBfreqsList.at(0.rand2(pBfreqsList.size));
	30.do{arg i, harmNum;
		score.add(
			synthDefPBells.note(item + 0.01.rrand(10), bellDur).freq_((freqRand*harmNum)/4);
		);
	};
};

// note parameter function - function to add notes to score
noteParamsFunc = { arg myParams;

    // construct score - iterate through noteParams array
    myParams.do({arg params;
        score.add(
            synthDef2.note(
                starttime: params.at(0), // starttime
                duration: params.at(1)   // dur
            ).dur_(params.at(1))         // dur
            .gain_(params.at(2))         // gain
            .carFreq_(params.at(3))      // carFreq
            .noiFreq_(
                qToNoiFreqFunc.value(
                    carFreq: params.at(3),
                    q: params.at(4)))    // noiFreq, calculated by qToNoiFreqFunc
            .modIndexGain_(params.at(5)) // modIndexGain
        );
    });
};

//call AMBell

note1 = amBellsynthDef.note(starttime: 13.53, duration: 20).dur_(20.0).gain_(0.0).carFreq_(202.4).modFreq_(1161.776).modIndexGain_(18.0).buffer_(buffer);

// add the buffer (wavetable) to the score
score.add(buffer);

// add notes to score
score.add(note1);


//call AMKick
noteParamsFunc.value(myParams: noteParams);

//call prismFunc
prismFunc.value(12.48, prismArray, 110.0, partialData);
prismFunc.value(21.38, prismArray, 440.0, partialData.scramble);

// write the soundfile out to disk
score.write(
	outputPath.standardizePath,
	sampleRate: sampleRate,
	headerFormat: headerFormat,
	sampleFormat: sampleFormat,
	options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);

score.saveToFile("~/Desktop/testCTKScore.scd".standardizePath);
)

 SFPlayer("~/Desktop/testCTK.wav".standardizePath).gui;

