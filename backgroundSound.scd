////////////////////   Synth 1   ////////////////////////
{a=PinkNoise.ar(1!2);60.do{a=BBandStop.ar(a,LFNoise1.kr(0.1.rand(~h1x)).exprange(80,5000),exprand(0.1,2))};LPF.ar(a,1e3)}.play

////////////////////   Synth 2   ////////////////////////
{LocalOut.ar(a=CombN.ar(BPF.ar(LocalIn.ar(2)*0.1+Saw.ar([32,33],0.02),2**LFNoise0.kr(4/3,4)*200,0.01)));a}.play

////////////////////   Synth 3   ////////////////////////
r{99.do{x={Pan2.ar(BPF.ar(Impulse.ar(08.linrand+0.5),9999.linrand,0.3.linrand,0.1),1.0.rand2)}.play;3.wait;x.release(9)}}.play

////////////////////   Global Reverb   ////////////////////////
{var in = In.ar(0,2);
	in = (in*0.2) + GVerb.ar(in, 200, 1, mul:0.2);
	ReplaceOut.ar(0, Limiter.ar(LeakDC.ar(in)))
}.play(addAction:\addToTail)


/*
////////////////////    REFERENCES    ////////////////////////

Synth 1 + 2 adapted from Nathaniel Virgo's work found at: http://sccode.org/1-4RA/fork
[Accssesed 12/06/15]

Synth 3 adapted from Nathaniel redfrik's work found at: http://sccode.org/1-4RA/fork

Global Reverb (triple super gverb) adapted from rukano's work found at: http://sccode.org/1-4EG
[Accssesed 12/06/15]

 */
