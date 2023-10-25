// see all quarks 
Quarks.gui

// install JITLibExtensions
Quarks.install("JITLibExtensions");

// start the server
s.boot; // Cmd+B or Ctrl+B

// Test and play the default sound
().play

// Play continuous sine wave
~mysound = {SinOsc.ar(50)}.play;
//  To stop the sound: Cmd+. or Ctrl+.
// or
~mysound.free;


// See what is going on with a Scope
~mysound = {SinOsc.ar(50)}.play;
s.scope

// Use another UGen to control a parameter
~mysound = {SinOsc.ar(XLine.ar(40, 3000, 10))}.play

// Feedback example with local feedback:
(
// Define the Specs for control parameters
Spec.add(\freq2, \freq);
Spec.add(\blockSize, [1,1024]);
Ndef(\sinefeedbackmachine, {
	var fb = LocalIn.ar(2);
	var sine1fb = fb[0];
	var sine2fb = fb[1];
	var sine1 = SinOsc.ar(\freq.kr(200) * (1+sine2fb));
	var sine2 = SinOsc.ar(\freq2.kr(100) * (1+sine1fb));
	LocalOut.ar([sine1, sine2]);
	[sine1,sine2]
});
)

Ndef(\sinefeedbackmachine).gui;
Ndef(\sinefeedbackmachine).play;


// Same idea, different implementation:
Ndef(\sine1, { SinOsc.ar(\freq.kr * (1 + Ndef(\sine2).ar ))});
Ndef(\sine1).gui;

Ndef(\sine2, { SinOsc.ar(\freq.kr * (1 + Ndef(\sine1).ar ))});
Ndef(\sine2).gui;

// Another way, more modular:
Ndef(\sine1, { SinOsc.ar(\freq.kr * (1 + \modulator.ar ))});
Ndef(\sine2, { SinOsc.ar(\freq.kr * (1 + \modulator.ar ))});
Ndef(\sine1).set(\modulator, Ndef(\sine2))
Ndef(\sine2).set(\modulator, Ndef(\sine1))

// Now try to set the modulator as the other Ndef
Ndef(\sine2).set(\modulator, Ndef(\sinefeedbackmachine))

// See all of this Ndefs in a Mixer:
NdefMixer(s);



// OSC Message example:
OSCdef(\receive, {|msg| Ndef(\sinefeedbackmachine).set(\freq, msg[1])}, "/setfreq")
n = NetAddr("localhost", NetAddr.langPort);
n.sendMsg("/setfreq", 300);
