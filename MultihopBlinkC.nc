#include "mymessage.h"
#include "TreeBuilding.h"
#include "MyCollection.h"


configuration MultihopBlinkC {
provides interface MyCollection;
}
implementation {
	components MainC, LedsC;//, UserButtonC;
	components SerialPrintfC, SerialStartC;
	components ActiveMessageC;
	components new TimerMilliC() as Timer0;
  	components new TimerMilliC() as Timer1;
	components new AMSenderC(AM_COLLECTIONDATA) as SenderD;
	components new AMReceiverC(AM_COLLECTIONDATA) as ReceiverD;
	components new AMSenderC(AM_TREEBUILDING) as SenderTreeC;
  	components new AMReceiverC(AM_TREEBUILDING) as ReceiverTreeC;
	components MultihopBlinkP as BlinkP;
	components PacketLinkC;
	components CC2420PacketC;
	//components Packet;
	components RandomC;
	//components MyCollection;
	
	MyCollection=BlinkP.MyCollection;

	//TreeConnection = BlinkP.TreeConnection;

	BlinkP -> MainC.Boot;
	BlinkP.Leds -> LedsC;
	//BlinkP.Notify -> UserButtonC;
	 BlinkP.TimerNotification -> Timer0;
  	BlinkP.TimerRefresh -> Timer1;
	BlinkP.AMControl -> ActiveMessageC.SplitControl;
	BlinkP.AMPacket  -> ActiveMessageC;
	BlinkP.AMSendD    -> SenderD;
	BlinkP.ReceiveD   -> ReceiverD;
	BlinkP.CC2420Packet -> CC2420PacketC;
	BlinkP.AMSend    -> SenderTreeC;
	BlinkP.Receive   -> ReceiverTreeC;
	BlinkP.PacketLink-> PacketLinkC;
	BlinkP.Packet -> ActiveMessageC;
	BlinkP.LPL -> ActiveMessageC;
	BlinkP.Random -> RandomC;
}

