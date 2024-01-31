s.options.protocol = \tcp;
s.boot;

(
~buffer = Buffer.read(s, "/home/bgola/workspace/ZKM/micro2.wav", action: {
	~src = Buffer(s);
	~buffer.numChannels.do{
		arg chan_i;
		FluidBufCompose.processBlocking(s,
			~buffer,
			startChan:chan_i,
			numChans:1,
			gain:~buffer.numChannels.reciprocal,
			destination:~src,
			destGain:1,
			action:{"copied channel: %".format(chan_i).postln}
		);
	};
});
)

// listen to the whole sample
// stop with Ctrl+. or Cmd+.
~src.play;
// Should be 1 channel
~src.numChannels;
// How long is the sample in seconds
~src.duration;

(
~indices = Buffer(s);
// FluCoMa slicer, will analyse the sample and slice it
// into many parts
// Check also:
//  - FluidBufOnsetSlice
//  - FluidBufAmpSlice
//  - FluidBufTransientSlice

FluidBufNoveltySlice.processBlocking(s,
	~src,
	indices:~indices,
	algorithm: 1,
	// You can play with the values of threshold and kernelSize
	threshold: 0.5,
	kernelSize: 13,
	action:{
		"found % slice points".format(~indices.numFrames).postln;
		"average duration per slice: %".format(
			~src.duration / (~indices.numFrames+1)).postln;
});
)

// Number of slices
~indices.numFrames;
~indices.plot;
// Plot the waveform + the slices
FluidWaveform(~src, ~indices);

// Ndef to play buffers
(
Ndef(\playbuf).addSpec(\startPos, [0,~buffer.numFrames]);
Ndef(\playbuf).addSpec(\rate, [-10,10]);
Ndef(\playbuf, {
	var env = Env.new([0,1,1,0],
		// divide duration by rate so that the envelope
		// always plays for the right amount of time
		[0,\duration.kr(1)/\rate.kr(1).abs,0]
	).ar(gate: \t_startBuf.kr);

	PlayBuf.ar(~buffer.numChannels,
		~buffer,
		startPos: \startPos.kr(0),
		rate: \rate.kr(1),
		// trigger by hand
		trigger: \t_startBuf.kr,
	) * env;
});
)
Ndef(\playbuf).gui;

(
// Randomly play a slice with random rate
var index = ~indices.numFrames.rand;
var rate = rrand(-2.0,2.0);
~indices.get(index, action: {|value|
	var orientation = rate.sign;
	~indices.get(index+orientation, action: {|valueNext|
		Ndef(\playbuf).set(
			\startPos, value,
			\duration, (valueNext - value).abs/~buffer.sampleRate,
			\t_startBuf, 1,
			\rate, rate
		);
	})
})
)

(
// Makes MFCC analysis of each slice
~analyses = FluidDataSet(s);
~indices.loadToFloatArray(action:{
	arg fa;
	var mfccs = Buffer(s);
	var stats = Buffer(s);
	var flat = Buffer(s);
	~mfccs = mfccs;
	fa.doAdjacentPairs{
		arg start, end, i;
		var num = end - start;
		FluidBufMFCC.processBlocking(s,~src,
			start,num,
			features:mfccs,
			numCoeffs:13,
			numBands:13,
			startCoeff:1);
		FluidBufStats.processBlocking(s,mfccs,stats:stats,select:[\mean]);
		FluidBufFlatten.processBlocking(s,stats,destination:flat);
		~analyses.addPoint("%_%".format("mfcc_", i).asSymbol,flat);

		"analyzing slice % / %".format(i+1,fa.size-1).postln;

		if((i%400) == 00){s.sync;}
	};
});
)

// Check the dataset
~analyses.print;

// Creates PCA dataset, reducing from 13 dimensions to 2
~twod = FluidDataSet(s);
FluidPCA(s, 2).fitTransform(~analyses, ~twod, action:{"pca done".postln});
~twod.print;

// Normalize it
~normalized = FluidDataSet(s);
FluidNormalize(s).fitTransform(~twod, ~normalized);
~normalized.print;

// A KDTree structure for the normalized data
// By default the kdtree will look for 1 closest neighbour
// without a distance limit
// see: https://learn.flucoma.org/reference/kdtree/
//      and the arguments to FluidKDTree numNeighbors and radius
~tree = FluidKDTree(s, numNeighbours: 1, radius: 0).fit(~normalized, action:{"fit done".postln});


~point = Buffer.alloc(s, 2);
~point.setn(0, 0.5, 1, 0.5);

(
// function to play a specific slice
~playSlice = { arg index;
	var rate = 1;// rrand(-2.0,2.0);
	~indices.get(index, action: {|value|
		var orientation = rate.sign;
		~indices.get(index+orientation, action: {|valueNext|
			Ndef(\playbuf).set(
				\startPos, value,
				\duration, (valueNext - value).abs/~buffer.sampleRate,
				\t_startBuf, 1,
				\rate, rate
			);
		})
	})
}
)

// plot the normalized data, and play when we click with the mouse
(
~point = Buffer.alloc(s, 2);
~normalized.dump({ arg dict;
	defer {
		FluidPlotter(dict: dict, mouseMoveAction: {|plotter, x,y|
			~point.setn(0, x, 1, y);
			~tree.kNearest(~point, 1, {|value|
				~playSlice.value(value.asString.split($_).last.asInteger)
			});
		})
	}
})
)

