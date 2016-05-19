configuration AppC {
//uses interface MyCollection;
}
implementation {
	//components MultihopBlinkP;
	components MultihopBlinkC;
	components AppP;
	components SerialPrintfC, SerialStartC;
	components new TimerMilliC() as StartTimer;
	components new TimerMilliC() as PeriodicTimer;
	components new TimerMilliC() as JitterTimer;
	components MainC, RandomC;

	AppP.Boot -> MainC;
	AppP.Random -> RandomC;
	AppP.MyCollection -> MultihopBlinkC;
	AppP.StartTimer -> StartTimer;
	AppP.PeriodicTimer -> PeriodicTimer;
	AppP.JitterTimer -> JitterTimer;
	//MyCollection = MultihopBlinkP.MyCollection;
}
