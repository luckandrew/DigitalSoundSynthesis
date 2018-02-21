
////////////////////////////////////////////////////////////////////////////////////////////////////
////Author: Andrew Luck
////DX Arts Digital Sound Synthesis 461 : Jo Anderson, Daniel Peterson
////Attribution: Code snippets from DXArts 461 Tutorials
////Last Modified: January 29th, 2018
////////////////////////////////////////////////////////////////////////////////////////////////////




// FM synthesis in terms of:
//
// freq : fundamental frequency
// n    : f1/f0 ratio
// p    : fc partial number
// im   : index of modulation


(

//////////////// DEFINE VARIABLES ////////////////

var synthDef;
var noteParams, start, dur, gain, freq;
var notePNumbers, noteModIndexs;
var numNotes;
var noteParamsFunc;
var cmRatioFunc, removeDuplicatesFunc, fmRatiosFunc;

// helper functions
var sinCosPanLaw;

// vars for NRT output
var outputPath, headerFormat, sampleFormat, sampleRate, numOutputChannels;
var germanTownPartialFreqs = [ 116, 232.4, 275.4, 348.6, 437.6, 585]; //array of harmonics
var thePartials = germanTownPartialFreqs;
var noteNRatio;
var score;
//var familySize = (thePartials.size - 1)

//////////////// BEGIN FAMILY GENERATION / ITERATION ////////////////

(thePartials.size - 1).do ({arg item, i;
	noteNRatio = ( thePartials.at(i+1) )/ thePartials.at(0);
	score = CtkScore.new;




/////////////// SET VARIABLE VALUES ///////////////

// set the NRT vars here...
outputPath = "~/Desktop/testCTK.wav"; // output file path
headerFormat = "WAV";                 // soundfile header format
sampleFormat = "int24";               // soundfile sample format
sampleRate = 44100;                   // sample rate
numOutputChannels = 2;                // stereo --> 2 channels
outputPath = "~/Desktop/testCTK" ++ (i+1) ++ ".wav"; //creates custom output path per partial


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

synthDef = CtkSynthDef.new(\myFMSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, carRatio = 1, modRatio = 1, modIndex = 1.0,  panAngle = 0.0;

    // variables
    var bus = 0;      // var to specify output bus: first output
    var carOsc, modOsc;  // oscillators
    var out;          // output!
    var amp;          // a few vars for synthesis
    var carFreq, modFreq;
    var modDev;
    var ampEnv;       // var for envelope signal


    // initial calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale
    carFreq = carRatio * freq;
    modFreq = modRatio * freq;
    modDev = modIndex * modFreq;

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    modOsc = SinOsc.ar(modFreq, 0, modDev);         // simple modulator (single sinusoid)
    carOsc = SinOsc.ar(carFreq + modOsc, 0, amp);   // simple carrier (single sinusoid)

    // apply the amplitude envelope
    carOsc = ampEnv * carOsc;

    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * carOsc;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)
});

///////////////// CREATE SCORE POPULATING FUNCTIONS //////////////////

// note parameter function - function to add notes to score
noteParamsFunc = { arg myParams;

    // construct score - iterate through noteParams array
    myParams.do({arg params;

        score.add(
            synthDef.note(
                starttime: params.at(0),                      // starttime
                duration: params.at(1)                        // dur
            ).dur_(params.at(1))                              // dur
            .gain_(params.at(2))                              // gain
            .freq_(params.at(3))                              // freq
            .carRatio_(cmRatioFunc.value(params.at(4), params.at(5)).at(0)) // carRatio
            .modRatio_(cmRatioFunc.value(params.at(4), params.at(5)).at(1)) // modRatio
            .modIndex_(params.at(6))                          // modIndex
        );
    });
};

///////////////// CREATE PARAMETER FUNCTIONS //////////////////


// function to remove duplicates
removeDuplicatesFunc = { arg array;
    var result;

    result = Array.newClear;

    array.do({ arg item;
        result.includes(item).not.if({
            result = result.add(item);
        })
    });
    result
};


// function to calculate c:m
// n, n >=1 ratio between f0 and f1
// p, p = 0, 1, 2, 3, ... partial number
cmRatioFunc = {arg n, p;
    var cm;

    p.even.if({
        cm = [                        // p is even case
            (p)/2 * (1 + n) + 1,      // carrier
            (1 + n)                   // modulator
        ]
    },{
        cm = [                        // p is odd case
            (p + 1)/2 * (1 + n) - 1,  // carrier
            (1 + n)                   // modulator
            ]
    });
    cm
};


// function to calculate FM spectrum ratios
fmRatiosFunc = {arg cm, k = 4;
    var ratios;

    ratios = (k + 1).collect({arg kNum;
        [cm.at(0) - (kNum * cm.at(1)), cm.at(0) + (kNum * cm.at(1))];
    });

    ratios = ratios.flatten.abs.sort;
    ratios = removeDuplicatesFunc.value(ratios);

    ratios;
};

///////////////// SET PARAMETER VALUES //////////////////

// -------------------------------------------
// parameters...




"noteNRatio is: ".post;
noteNRatio.postln;


    start = 0;
    dur = 2;
    gain = -12;
    freq = 220;
    numNotes = thePartials.size;
    notePNumbers = Array.series(numNotes, 0);
    noteModIndexs = Array.fill(numNotes, {0.7});




// -------------------------------------------
// use -collect (iteration!) to pack into array, noteParams
noteParams = numNotes.collect({arg i;
    Array.with(
        start + (i * dur),   // start
        dur,                 // dur
        gain,                // gain
        freq,                // freq
        noteNRatio,   // nRatio
        notePNumbers.at(i),  // pNumber
        noteModIndexs.at(i)) // index of modulation


});

	"noteParams is: ".post;
noteParams.postln;

// let's post the note paramater data for inspection
"".postln;
"--------------------------------------------------------".postln;
"[ start, dur, gain, freq, nRatio, pNumber, modIndex ]".postln;
"--------------------------------------------------------".postln;
noteParams.do({arg item, i;
    item.postln;
});
"--------------------------------------------------------".postln;
"".postln;


// let's post the partial ratios for inspection
"".postln;
"--------------------------------------------------------".postln;
"[carRatio, modRatio] --> [ p0Ratio, p1Ratio, p2Ratio... ]".postln;
"--------------------------------------------------------".postln;
noteParams.do({arg item, i;
    cmRatioFunc.value(n: noteNRatio, p: notePNumbers.at(i)).post;
    " --> ".post;
    fmRatiosFunc.value(cm: cmRatioFunc.value(n: noteNRatio, p: notePNumbers.at(i))).postln;
});
"--------------------------------------------------------".postln;
"".postln;


///////////////// EVALUATE FUNCTIONS //////////////////

// call noteParamsFunc to add notes to score!
noteParamsFunc.value(noteParams);


///////////////// RENDER THE SCORE //////////////////

// write score to sound file with the -write message
score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);

});  //closes the thePartials.do iteration


)

///////////////// OPEN THE FILES //////////////////


(
SFPlayer("~/Desktop/testCTK1.wav".standardizePath).gui;
SFPlayer("~/Desktop/testCTK2.wav".standardizePath).gui;
SFPlayer("~/Desktop/testCTK3.wav".standardizePath).gui;
SFPlayer("~/Desktop/testCTK4.wav".standardizePath).gui;
SFPlayer("~/Desktop/testCTK5.wav".standardizePath).gui;
)