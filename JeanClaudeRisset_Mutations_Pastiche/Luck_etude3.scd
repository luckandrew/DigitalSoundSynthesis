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

//////////////// DEFINE VARIABLES ////////////////

//ssb riser vars

var score, synthDef;
var tableSize, bufferCos, bufferSin;

var modulatorPartialGains;
var modulatorPartialDataCos, modulatorPartialDataSin;
var noteParams, start, dur, gain;
var noteModFreqs, noteCarFreqs;
var noteParamsFunc;
var numNotes;

//noise explosion vars

var noise0SynthDef, noise1SynthDef, noise2SynthDef;
var nZnoteParams, nZstart, nZdur, nZgain, nZmyParams, noteNoiFreqs, mySynthDef;
var nZnoteParamsFunc;
var nZnumNotes;

// bell prism vars

var additiveFunc;
var partialGains = [1.0, 0.67, 1.0, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1.0, 1.33].ampdb; // gains for Risset Bell
var partialRatios = [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2.0, 2.74, 3.0, 3.76, 4.07]; // ratios for each partial
var partialDurs = [1.0, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075]; // duration scaling;
var partialData, noteArray, rhythmArray, noteArray3, noteSeed, rhythmArray3;
var prismFunc, prismArray, prismSeed, synthDefPrism;

// vars for PBells

var synthDefPBells, pBfreqs, bellDur, pBellenv, pBpitchEnv, pBfreqsList, pBnumNotes, pBdensityEnv, bellDurArray;

//vars for AM Bell
var note1, amBellsynthDef;
var buffer;
var carrierPartialGains;

// helper functions
var sinCosPanLaw;

// vars for NRT output
var outputPath, headerFormat, sampleFormat, sampleRate, numOutputChannels;

/////////////// SET VARIABLE VALUES ///////////////////////////////////////////////////////////////////////

// set the NRT vars here...
outputPath = "~/Desktop/testCTK.wav"; // output file path
headerFormat = "WAV";                 // soundfile header format
sampleFormat = "int24";               // soundfile sample format
sampleRate = 44100;                   // sample rate
numOutputChannels = 2;                // stereo --> 2 channels

// create a score
score = CtkScore.new;

/////////////// DEFINE SYNTH HELPER FUNCTIONS /////////////////////////////////////////////////////////

// sine-cosine panning law coefficient function
// angle argument in degrees

sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180 * pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

///////////////  Bell Prism Synth Def ///////////////////////////////////////////////////////////////////////

//thisThread.randSeed = 1502;
synthDefPrism = CtkSynthDef.new(\mySinOscSynth, {arg dur, gain = -16, freq = 440.0, ris = 0.1, panAngle;
	var env, envGen, amp;
	env = EnvGen.kr(Env([0, 1, 0], [ris, dur - ris], [4, -4])); // env define within synthDef
	amp = env * gain.dbamp * 0.1;
	//panAngle = EnvGen.kr(Env.new([-1, 0, 1], [dur, 1], \exp));
	Out.ar(0,
		SinOsc.ar(freq, 0, amp * sinCosPanLaw.value(panAngle))

	)
});


///////////////// SSB Riser Synth Def /////////////////////////////////////////////////////////////////////

synthDef = CtkSynthDef.new(\mySSBSynth, {arg dur, gain, ris = 0.1, dec = 0.1, carFreq = 440.0, modFreq = 440.0,  panAngle = 0.0, bufferCos = 0, bufferSin = 1;

    // variables
    var bus = 0;      // var to specify output bus: first output
    var carOsc, modOsc;  // oscillators
    var ssb;          // ssb signal!
    var out;          // output!
    var amp;          // a few vars for synthesis
    var ampEnv;       // var for envelope signal


    // calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec,  curve: 'sine'),  // NOTE: some SC versions click with 'lin'
        timeScale: dur
    );

    modOsc = Osc.ar([bufferCos, bufferSin], modFreq, 0, amp); // complex complex modulator, in quuadrature: phase =  [cos, sin]
    carOsc = SinOsc.ar(carFreq, phase:[pi/2, 0]); // simple carrier, in quadrature: phase = [cos, sin]

    // generate single sideband - upper sideband
    ssb = ((carOsc.at(0) * modOsc.at(0)) - (carOsc.at(1) * modOsc.at(1)));

    // apply the amplitude envelope
    ssb = ampEnv * ssb;

    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * ssb;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)

});

///////////////// Noise Synth Def ////////////////////////////////////////////////////////////////////////

// LFNoise0
noise0SynthDef = CtkSynthDef.new(\myLF0Synth, {arg nZdur, nZgain, ris = 0.1, dec = 0.1, noiFreq = 440.0,  panAngle = 0.0;

    // variables
    var bus = 0;      // var to specify output bus: first output
    var noise;        // noise
    var out;          // output!
    var amp;          // a few vars for synthesis
    var ampEnv;       // var for envelope signal

    // initial calcs
    amp = nZgain.dbamp; // convert from gain in dB to linear amplitude scale

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
        //Env.linen(ris, 1.0 - (ris + dec), dec),
		Env.new([1, -90.dbamp], [1], \exp),
        timeScale: nZdur * 2
    );

    noise = LFNoise0.ar(noiFreq);              // MusicV RANDH (sample-and-hold noise)

    // apply the amplitude envelope
    noise = amp * ampEnv * noise;

	panAngle = EnvGen.kr(
		Env.new([-45, 0, 45], [1, 0], \lin));

    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * noise;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)
});


////////////////// PB Bells Synth Def//////////////////////////////////////////////////////////////////////

// CtkSynthDef assigned to var called 'synthDefPBells'
synthDefPBells = CtkSynthDef.new(\mySinOscSynth2, {arg freq, panAngle;

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

    //panAngle = Env.new([-45, 0, 45], [1,1], \exp);
	//panAngle = -45.rand2(45);

	 out = sinCosPanLaw.value(panAngle) * osc;  // <-- Panning happens here!

    // out!!
    Out.ar(         // Out UGen
        bus,        // 1st arg of Out: (set to a default value - the 1st output)
        out         // 2nd arg of Out: (two channels)
    )
});

////////////////////AM Bell Synth Def//////////////////////////////////////////////////////

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


////////////////////Additive Func//////////////////////////////////////////////////////

// function to add individual notes to our score for additive synthesis
additiveFunc = {arg start, dur, gain = -24, ris, freq, partialData, panAngle; // pass in values

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
		thisPartialGain = thisPartialGain; // add gains together
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
			synthDefPrism.note(start, thisPartialDur)
			.dur_(thisPartialDur)
			.gain_(thisPartialGain)
			.freq_(thisPartialFreq)
			.ris_(ris)
			.panAngle_(panAngle)
		);

	})
};



///Bell Prism Func////

prismFunc = {arg start, prismArray, prismSeed, partialData; // arguments are start time and a note array [start times, durs, amps]
	noteArray3.do{arg note, i; //iterate over that array
		var numHarms, harmArray, partialArray, noteDur, noteStart, noteGain;
		noteStart = note[0]; // unpack note start time
		noteDur = note[1]; // unpack note duration
		noteGain = note[2] * 0.25 ; // unpack note gain
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



///////////////// SET BUFFER VALUES //////////////////


// -------------------------------------------
// score parameters
tableSize = 2.pow(13);           // for the wavetable

// See above, Attribution [2]
modulatorPartialGains = [ -18, 0, -19, -17, -27, -19, -29, -47, -34, -58, -48, -56, -51, -47, -63, -66, -60, -58, -54, -64 ];

// prepare data for quadrature modulator wavetables: partial frequency, amplitude and phase
// Cosine data
modulatorPartialDataCos = modulatorPartialGains.collect({arg partialGain, i;
    var partialNum;

    partialNum = i + 1;
    [partialNum, partialGain.dbamp / (modulatorPartialGains.dbamp.sum), pi/2] // partial num, normalized gain, phase = pi/2 (cos)
});
modulatorPartialDataCos = modulatorPartialDataCos.flatten;

// Sine data
modulatorPartialDataSin = modulatorPartialGains.collect({arg partialGain, i;
    var partialNum;

    partialNum = i + 1;
    [partialNum, partialGain.dbamp / (modulatorPartialGains.dbamp.sum), 0] // partial num, normalized gain, phase = 0 (sin)
});
modulatorPartialDataSin = modulatorPartialDataSin.flatten;


///////////////// CREATE BUFFERS //////////////////

// create the wavetables buffer for modulator - MUST be wavetable format:
// we need two because SSB needs two versions of the modulator in quadrature phase
// also... we'll use -sine3 because we can specify partial frequency, amplitude and phase
bufferCos = CtkBuffer.buffer(tableSize).sine3(time: 0.0, normalize: 0, wavetable: 1, clear: 1, args: modulatorPartialDataCos);
bufferSin = CtkBuffer.buffer(tableSize).sine3(time: 0.0, normalize: 0, wavetable: 1, clear: 1, args: modulatorPartialDataSin);

///////////////// CREATE SCORE POPULATING FUNCTIONS //////////////////

// note parameter function - function to add notes to score
noteParamsFunc = { arg myParams;

    // construct score - iterate through noteParams array
    myParams.do({arg params;
        score.add(
            synthDef.note(
                starttime: params.at(0), // starttime
                duration: params.at(1)   // dur
            ).dur_(params.at(1))         // dur
            .gain_(params.at(2))         // gain
            .carFreq_(params.at(3))      // carFreq
            .modFreq_(params.at(4))      // modFreq
            .bufferCos_(params.at(5))    // bufferCos
            .bufferSin_(params.at(6));   // bufferSin
        );
    });
};


///////////////// Noise Explosion Score //////////////////////////////////////////////////

// note parameter function - function to add notes to score
nZnoteParamsFunc = { arg mySynthDef, nZmyParams;

    // construct score - iterate through noteParams array
    nZmyParams.do({arg params;
        score.add(
            noise0SynthDef.note(
                starttime: params.at(0), // starttime
                duration: params.at(1)   // dur
            ).nZdur_(params.at(1))         // dur
            .nZgain_(params.at(2))         // gain
            .noiFreq_(params.at(3))      // noiFreq
        );
    });
};

///////////////// SSB Riser Params //////////////////////////////////////////////////////

// //
numNotes = 30; // number of notes to generate
start = 0;
dur = 0.1;
gain = -12;
noteCarFreqs = Array.fill(numNotes, { rrand(0.0, -440.0) }).normalize(-440.0, 0.0);
noteCarFreqs = noteCarFreqs.sort.reverse;
noteModFreqs = 110.0 - noteCarFreqs;

// -------------------------------------------
// use -collect (itteration!) to pack into array, noteParams
noteParams = numNotes.collect({arg i;
    Array.with(start + (i * dur), dur, gain, noteCarFreqs.at(i), noteModFreqs.at(i), bufferCos, bufferSin)
});



///////////////// Noise Explosion Params //////////////////////////////////////////////////////

nZnumNotes = 1;
start = 2.98;
nZdur = 5;
nZgain = -6;
noteNoiFreqs = 220.0 * Array.geom(nZnumNotes, 1, 2);// <--- This is our "data of interest"

// -------------------------------------------
// use -collect (iteration!) to pack into array, noteParams
nZnoteParams = nZnumNotes.collect({arg i;
    Array.with(start + (i * nZdur), nZdur, nZgain, noteNoiFreqs.at(i))
});

///////////////// BellPrism Params //////////////////////////////////////////////////////

// group partial durs, gains and ratios into a new array
partialData = [partialDurs, partialGains, partialRatios].flop;
"partialData is: ".post;
partialData.postln;


////////////////prismFunc params/////////////////////////////////////////////////////

prismArray = Array.series(partialGains.size, 0, 0.25);  //start times
// create my note array with rhythms, a random duration and a random amp
noteArray3 = prismArray.size.collect{arg i;
	[prismArray[i], 5, -30];
};
"prismArray is: ".post;
prismArray.postln;


///////////////// PB Bells Params //////////////////////////////////////////////////////

// scoring parameters
bellDur = 3;
// bellDurArray = Array.geom(10, 1, 0.5).reverse;

pBfreqsList = ([0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2.0, 2.74, 3.0, 3.76, 4.07] * 440).scramble;

pBfreqs = [pBfreqsList.at(1), pBfreqsList.at(2)];

///////////////// POPULATE THE SCORE //////////////////

pBdensityEnv  = EnvGen.kr(Env([0.000001, 1, 1, 0.000001], [0, 2, 3, 0.00001], \exp));

pBnumNotes = 1;

//play 10 notes using our SynthDef.

	pBnumNotes.do{arg item;
	var freqRand;
	freqRand = pBfreqsList.at(0.rand2(pBfreqsList.size));
	30.do{arg i, harmNum;
		score.add(
			synthDefPBells.note(item + 16.07.rrand(30.00), bellDur).freq_((freqRand*harmNum)/4);
		);
	};
};

/////////////////  AM Bells Params //////////////////////////////////////////////////////

// score parameters
tableSize = 2.pow(13);           // for the wavetable

partialGains = Harmonics.new(3);
carrierPartialGains = partialGains.rand(-3.5, 8.5);  //generate first three harmonics from 4b


///////////////// CREATE BUFFERS //////////////////

// create the wavetable buffer for carrier - MUST be wavetable format:
buffer = CtkBuffer.buffer(tableSize).sine1(time: 0.0, normalize: 1, wavetable: 1, clear: 1, args: carrierPartialGains.dbamp);

// -------------------------------------------
// prepare to synthesise...

///////////////// POPULATE THE SCORE //////////////////////////////////////////////////////

// NOTE: the buffer must be added to the score for the CtkSynthDef to access!
score.add(bufferCos);
score.add(bufferSin);


///////////////// SSB Riser Call //////////////////

// call noteParamsFunc to add notes to score!
noteParamsFunc.value(noteParams);

///////////////// Noise Explosion ////////////////////////////////////////////////////////////////////////

// call noteParamsFunc to add notes to score!
// NOTE: We've added mySynthDef as an argument to noteParamsFunc.
//       mySynthDef could be included in the noteParams list, instead....
//
nZnoteParamsFunc.value(mySynthDef: noise0SynthDef, nZmyParams: nZnoteParams); // use LFNoise0


///////////////// Bell Prism Call /////////////////////////////////////////////////////////////////////

//call prismFunc
prismFunc.value(8.13, prismArray, 440.0, partialData);
prismFunc.value(10.13, prismArray, 220.0, partialData);
prismFunc.value(12.13, prismArray, 110.0, partialData);

///////////////// AM Bell Call /////////////////////////////////////////////////////////////////////

note1 = amBellsynthDef.note(starttime: 22.0, duration: 20).dur_(20.0).gain_(0.0).carFreq_(202.4).modFreq_(1161.776).modIndexGain_(18.0).buffer_(buffer);

// add the buffer (wavetable) to the score
score.add(buffer);

// add notes to score
score.add(note1);

///////////////// RENDER THE SCORE ////////////////////////////////////////////////////////////////////////

// write score to sound file with the -write message
score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

SFPlayer("~/Desktop/testCTK.wav".standardizePath).gui;