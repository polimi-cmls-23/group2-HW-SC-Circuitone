s.reboot;

(
SynthDef(\scopes,{

	var inputSignal, outputSignal;
	var inputBus, outputBus;
	var inputScope, outputScope;
	var myPlot;

	var gain;

	gain = 10;

	inputBus = Bus.audio(s, 2);
	outputBus = Bus.audio(s, 2);

	inputSignal = SinOsc.ar([220, 440], mul:0.5);

	//********************************************************
	// Transfer functions

	// tanh behaviour
	/*
	myPlot = {
		var a;
		a = Line.ar(-3, 3, 0.01);
		a.tanh
	}.plot
	*/
	outputSignal = (gain * inputSignal).tanh;

	//********************************************************
	Out.ar(inputBus, inputSignal);
	Out.ar(0, outputSignal);

	w = Window.new("my own scope", Rect(20, 20, 400, 500));
	w.view.decorator = FlowLayout(w.view.bounds);
	inputScope = Stethoscope.new(s, numChannels: 2, index: inputBus.index, view:w.view);
	outputScope = Stethoscope.new(s, numChannels: 2, index: 0, view:w.view);
	{
		var a;
		a = Line.ar(-3, 3, 0.01);
		a.tanh
	}.plot(name: "Transfer function");
	w.onClose = { inputScope.free; outputScope.free; };
	w.front;

}).send(s);
)

Synth(\scopes);

~input.free;
~output.free;
~inputBus.free;
~outputBus.free;


(
{
    var a;
    a = Line.ar(-3, 3, 0.01);
    a.tanh
}.plot
)