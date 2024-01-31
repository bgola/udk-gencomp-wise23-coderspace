s.boot;

b = Buffer.alloc(s, 16);
b.plot;

b.fill(0, 2, 0.4, 3, 7, 0.6);

f = Buffer.read(s, "/home/bgola/.local/share/SuperCollider/Recordings/SC_240120_180224.wav")


f.play;
f.numFrames
(
Ndef(\playbuf).addSpec(\startPos, [0,1]);
Ndef(\playbuf).addSpec(\rate, [-10,10]);
Ndef(\playbuf, {
	// PlayBuf: plays a buffer, controls rate of
	// playback , can retrigger and change the
	// start position
	PlayBuf.ar(f.numChannels,
		f,
		// Random position:
		// startPos: f.numFrames * WhiteNoise.kr.abs,
		startPos: f.numFrames * \startPos.kr(0),
		rate: \rate.kr(1),
		// trigger by hand
		// trigger: \t_startBuf.kr(0),
		// trigger when start position has changed
		// We chain different triggers by using
		// the "or" binary operator: |
		trigger: Changed.kr(\startPos.kr) | Impulse.kr(0.5) | Impulse.kr(0.3),
	);
});
)
Ndef(\playbuf).gui;

Ndef(\playbuf).gui;
Ndef(\playbuf).set(\t_startBuf, 1)


g = Buffer.readChannel(s, "/home/bgola/.local/share/SuperCollider/Recordings/SC_240120_180224.wav", channels: [0]);
~winenv.plot
(
~winenv = Env([0, 1, 0], [0.5, 0.5], [-2, 2]);
~bufwin = Buffer.sendCollection(s, ~winenv.discretize, 1);
Ndef(\grainbuf).addSpec(\startPos, [0,1]);
Ndef(\grainbuf).addSpec(\startPos, [-10,10]);
Ndef(\grainbuf, {
	GrainBufJ.ar(2,
		trigger: Changed.kr(\startPos.kr) | Impulse.kr(0.5*30) | Impulse.kr(0.3*30),
		sndbuf: g,
		pos: \startPos.kr,
		dur: 0.3,
		envbufnum: ~bufwin,
		pan: 0,
		rate: \rate.kr(1),
		grainAmp: 1 // LFNoise0.kr(10.5).abs
	) * LFNoise0.kr(10.5);
});
)
Ndef(\grainbuf).gui;


