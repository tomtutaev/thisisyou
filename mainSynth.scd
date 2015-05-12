////////////////////    1) Busses    ////////////////////////
(
~h1x = Bus.control(s, 1);   // kinect, left hand x position
~h1y = Bus.control(s, 1);   // kinect, left hand y position
~h1z = Bus.control(s, 1);   // kinect, left hand z position

~h2x = Bus.control(s, 1);   // kinect, right hand x position
~h2y = Bus.control(s, 1);   // kinect, right hand y position
~h2z = Bus.control(s, 1);   // kinect, right hand z position

~busSynth = Bus.audio(s, 2); // added reverb bus

)


////////////////////    2) Main Synth Left Hand    ////////////////////////
(
SynthDef(\mainsynthL, {
	arg out = 0, gate = 1, atk = 5.0;

	var env, clockRate, clockTime, clock, centerFreq, freq, panPos, patch; //set up variables 

	env = EnvGen.kr(Env.adsr(atk,1 , 1), gate, doneAction: 2);

	centerFreq = 1300 * 10.asWarp.map(In.kr(~h1y)) + 160; // setup left hand frequency  

	clockRate = 1 * In.kr(~h1x) + 1; // setup note speed

	clockTime = 2*clockRate.reciprocal; // setup note speed

	clock = Impulse.kr(clockRate, 1); // setup note speed

	freq = Latch.kr(WhiteNoise.kr((~h1x),centerFreq * 1, centerFreq), clock);

	panPos = Latch.kr(WhiteNoise.kr(~h1y), clock, 400); // setup random pan 

	patch = CombN.ar(
		Pan2.ar(
			SinOsc.ar(freq, 0, Decay2.kr(clock, 0.3 * clockTime, 0.1 * clockTime)),
			panPos
		), 0.3, 0.3, 1);
	Out.ar(out, env * patch);
}).add;
)


////////////////////    3) Main Synth Right Hand    ////////////////////////
(
SynthDef(\mainsynthR, {
	arg out = 0, gate = 1, atk = 5.0;

	var env, clockRate, clockTime, clock, centerFreq, freq, panPos, patch;

	env = EnvGen.kr(Env.adsr(atk,1 , 1), gate, doneAction: 2);

	centerFreq = 1300 * 10.asWarp.map(In.kr(~h2y)) + 160;

	clockRate = 5 * In.kr(~h2x) + 1;

	clockTime = 3*clockRate.reciprocal;

	clock = Impulse.kr(clockRate, 1);

	freq = Latch.kr(WhiteNoise.kr((~h2z),centerFreq * 1, centerFreq), clock);

	panPos = Latch.kr(WhiteNoise.kr(~h2y), clock, 400);

	patch = CombN.ar(
		Pan2.ar(
			SinOsc.ar(freq, 0, Decay2.kr(clock, 0.3 * clockTime, 0.1 * clockTime)),
			panPos
		), 0.3, 0.3, 1);
	Out.ar(out, env * patch);
}).add;
)


////////////////////    4) Reverb Left Hand     ////////////////////////
(
SynthDef(\reverb_efL, {
	arg		amp=1, mix=1, revTime=4, preDel=0.1, lpfFreq=4500, outBus=0; 
	var		sig, verbSig, totalSig, outSig;
	mix = In.kr(~h1y).clip(0, 1);
	sig = In.ar(~busSynth, 2); // triggered by busSynth
	preDel = 0.5; // pre delay
	verbSig = DelayN.ar(sig, preDel, preDel);  //pre-delay
	totalSig = 0;
	12.do{
		verbSig = AllpassN.ar(verbSig, 0.06, {Rand(0.001,0.06)}!2, revTime);
		verbSig = LPF.ar(verbSig, lpfFreq);
		totalSig = totalSig + verbSig;
	};
	totalSig = XFade2.ar(sig, totalSig, mix.linlin(0,1,-1,1));  // dry/wet mix
	outSig = totalSig * amp;
	Out.ar(outBus, outSig);
}).add;
)


////////////////////    5) Reverb Right Hand     ////////////////////////
(
SynthDef(\reverb_efR, {
	arg		amp=1, mix=1, revTime=4, preDel=0.1, lpfFreq=4500, outBus=0;
	var		sig, verbSig, totalSig, outSig;
	mix = In.kr(~h2y).clip(0, 1);
	sig = In.ar(~busSynth, 2);
	preDel = 0.5;
	verbSig = DelayN.ar(sig, preDel, preDel);  //pre-delay
	totalSig = 0;
	12.do{
		verbSig = AllpassN.ar(verbSig, 0.06, {Rand(0.001,0.06)}!2, revTime);
		verbSig = LPF.ar(verbSig, lpfFreq);
		totalSig = totalSig + verbSig;
	};
	totalSig = XFade2.ar(sig, totalSig, mix.linlin(0,1,-1,1));  //dry/wet mix
	outSig = totalSig * amp;
	Out.ar(outBus, outSig);
}).add;
)


//////////////////// 6) OSC Left Hand   ////////////////////////
(
OSCFunc({
	|msg |
	~h1x.set(msg[1]); // create messages for OSC
	~h1y.set(msg[2]);
	~h1z.set(msg[3]);
},  '/lefthand/', nil);
)


//////////////////// 7) OSC Right Hand   ////////////////////////
(
OSCFunc({
	|msg |
	~h2x.set(msg[1]);
	~h2y.set(msg[2]);
	~h2z.set(msg[3]);
},  '/righthand/', nil);
)

////////////////////    8) Launch Synths    ////////////////////////
~sahliquid = Synth(\mainsynthL);

~sahliquid = Synth(\mainsynthR);

~synth = Synth(\reverb_efL);

~synth = Synth(\reverb_efR);


/*
////////////////////    REFERENCES    ////////////////////////

Busses, Main SynthL, Main SynthR, OSC left + right hand adapted from:
https://github.com/genekogan/LeapMotion-SuperCollider-Instruments/blob/master/sahliquidities.scd
[Accssesed 12/06/15]

Reverb Left + Right hand adapted from:
https://github.com/genekogan/LeapMotion-SuperCollider-Instruments/blob/master/marimba.scd
[Accssesed 12/06/15]

*/


