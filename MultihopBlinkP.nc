#include <Timer.h>
//#include <UserButton.h>
#include <printf.h>
#include "MyCollection.h"
#include "TreeBuilding.h"


module MultihopBlinkP {
provides{
	interface MyCollection;
}
	uses {
			interface SplitControl as AMControl;
			interface AMPacket as AMPacketC;
			interface AMPacket as AMPacketD;
			interface AMSend as AMSendC;
			interface Receive as ReceiveC;
			interface PacketLink;
			//interface Notify<button_state_t>;
			interface Boot;
			interface Leds;
			interface LowPowerListening as LPL;
			interface CC2420Packet;
			interface Random;
			interface Packet;
			interface AMSend as AMSendD;
			interface Receive as ReceiveD;
			//interface TreeConnection;
			interface Timer<TMilli> as TimerRefresh;
	    		interface Timer<TMilli> as TimerNotification;
			//interface CollectionPacket;
	}
}
implementation {
    
#define NUM_RETRIES 3
#define REBUILD_PERIOD (60*1024L)
	
	uint8_t counter=0;
	bool sending;
  	uint16_t current_seq_no;
  	uint16_t current_parent;
  	uint16_t current_hops_to_sink; 
  	uint8_t current_rssi_to_parent; 
  	uint16_t num_received;

	//command void buildTree();
	//command void send(MyData* data1);

	/* a packet buffer that we will use for outgoing
	 * messages */
	message_t output;
	MyData data;
	CollectionData collData;
	
	/* a flag to memorize that the radio is busy and
	 * we don't have ownership of the output buffer
	 * so we cannot touch it */
	bool sending;
	
	task void sendNotification(); // just a prototype
	
	event void Boot.booted() {
		/* setting up the LPL layer */
		call LPL.setLocalWakeupInterval(LPL_DEF_REMOTE_WAKEUP);
 		current_parent = TOS_NODE_ID;
    		current_seq_no = 0;
    		num_received = 0;
		/* turning on the radio */
		call AMControl.start();
		//post sendNotification();
    }
	
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS){
      	if (TOS_NODE_ID == 1){
        // NODE 0 IS THE SINK WHICH PERIODICALLY REBUILDS THE TREE
        call TimerRefresh.startPeriodic(REBUILD_PERIOD);
      }
    } else { 
      call AMControl.start();
    }
  }
	
  /*  event void Notify.notify( button_state_t state, MyData* data, uint16_t source){
        if ( state==BUTTON_PRESSED ){
			counter = (counter + 1) % 8;
			
			call Leds.set(counter);
			post sendNotification();
        }
    }
*/
	command void MyCollection.buildTree()
{
	call LPL.setLocalWakeupInterval(LPL_DEF_REMOTE_WAKEUP);
 		current_parent = TOS_NODE_ID;
    		current_seq_no = 0;
    		num_received = 0;
		/* turning on the radio */
		call AMControl.start();
}

	command void MyCollection.send(MyData* data1){
		//data = &data1;
		//post sendNotification();
		//error_t error;
		MyData* m = (MyData*)data1;
		data.seqn = current_seq_no;
		collData.from=current_parent;
		sending=TRUE;
		call AMSendD.send(TOS_NODE_ID + 1, &data1, sizeof(MyData));
	}

	//event void parentUpdate(uint16_t parent);
	/* a helper function that sends the counter
	 * to a node with the ID = our ID + 1 */
	task void sendNotification(){
		error_t error;
		
		if (!sending) {
			//MyMessage* m = call AMSend.getPayload(&output, sizeof(MyMessage));
			TreeBuilding* msg = (TreeBuilding*) (call AMSendC.getPayload(&output, sizeof(msg)));
			//m->counter = counter;
			msg->seq_no = current_seq_no;
    			msg->metric = current_hops_to_sink;
			//call PacketLink.setRetries(&output, NUM_RETRIES);
			call Packet.clear(&output);
			
			if ((error = call AMSendC.send(AM_BROADCAST_ADDR, &output,
    				sizeof(TreeBuilding))) == SUCCESS){
      					call Leds.led2On();
					//printf("message transferred\n",AM_BROADCAST_ADDR);
      					sending = TRUE;
   				 } 
    				else {
      				printf("ERROR ERROR  routing", "\n\n\n\nERROR\t%u\n", error);
     				 // retry after a random time
      				call TimerNotification.startOneShot(call Random.rand16()%100);
    				}  
		}
		else
		{
			//we dont care
			printf("error");
		}
	}

		event void TimerRefresh.fired(){
	    if (!sending){
	      current_seq_no++;
	      post sendNotification();
	    }
	  }

	  event void TimerNotification.fired(){
	    if (!sending){
	      post sendNotification();
	    }
	  }


		event void AMSendC.sendDone(message_t* msg, error_t error)
		  {
		    if (error == SUCCESS)
		      sending = FALSE;
		    else // retry sending the notification
		      call TimerNotification.startOneShot(call Random.rand16()%100);
		  }

	inline uint8_t getRssi(message_t* msg){
    		uint8_t rssi ;
    		rssi = (int8_t)call CC2420Packet.getRssi(msg) - 45 ; // or CC2420Packet.getLqi(msg);
    		return rssi;
  		}
	inline void updateParent(uint16_t new_parent, uint16_t new_hops_to_sink, uint8_t new_rssi_to_parent){
  		current_parent=new_parent;
  		current_hops_to_sink=new_hops_to_sink; 
  		current_rssi_to_parent=new_rssi_to_parent;
		//printf("INSIDE RECIEVE\n", "Message delivered is\n", current_parent, 
  		//printf("INSIDE UPDATE routing", "NEW PARENT\t%u\tCOST\t%u\tRSSI\t%hhi\n", current_parent, current_hops_to_sink,current_rssi_to_parent );
  		// Inform the collection layer about the new parent
  		//signal TreeConnection.parentUpdate(current_parent);
  		// Inform neighboring nodes after a random time
  		call TimerNotification.startOneShot(call Random.rand16()%100);
		}
	 event MyData* ReceiveD.receive(MyData* msg, void* payload, uint8_t len) {
		am_addr_t from;
		from = call AMPacketD.source(msg);
		signal MyCollection.receive(from, payload);
    		return msg;
  	}
	
	event message_t* ReceiveC.receive(message_t* msg, void* payload, uint8_t len) {
		/*am_addr_t from;
		MyMessage* m = (MyMessage*)payload;

		if (length != sizeof(MyMessage)) // sanity check
			return msg; // returning the incoming buffer back to the stack
    	
		from = call AMPacket.source(msg);
		printf("Received a counter %d from node %d\n", m->counter, from);
		counter = m->counter;
		call Leds.set(counter);
		send_to_next();
		return msg; // returning the incoming buffer back to the stack*/
		signal MyCollection.receive(call AMPacketC.source(msg), payload);
		if (len == sizeof(TreeBuilding) && TOS_NODE_ID != 1){
      TreeBuilding* treemsg = (TreeBuilding*) payload;
      uint16_t hops_to_sink_through_sender = treemsg->metric + 1;
      uint8_t rssi_to_sender= getRssi(msg);
      num_received++;
	//printf("RECIVED MESSAGE is \n",msg);
     //  printf("routing", "Received MSG# %u\tSOURCE %u\tSEQ %u\tHops %u\tRSSI %hhi\n", num_received, call AMPacket.source(msg), treemsg->seq_no, hops_to_sink_through_sender, rssi_to_sender); 
      if (treemsg->seq_no < current_seq_no)
        return msg;
      if (treemsg->seq_no > current_seq_no){
        //New refresh round, therefore update the seqno and parent
        //printf("routing", "New Round, New Parent\n"); 
        current_seq_no = treemsg->seq_no;
        updateParent(call AMPacketC.source(msg),hops_to_sink_through_sender, rssi_to_sender );
      } else if (treemsg->seq_no == current_seq_no) {
       if (current_hops_to_sink > hops_to_sink_through_sender){
         // printf("routing", "New Parent with less hops to sink\n"); 
          updateParent(call AMPacketC.source(msg),hops_to_sink_through_sender, rssi_to_sender);
        }
        else if ((current_hops_to_sink == hops_to_sink_through_sender) && (current_rssi_to_parent< rssi_to_sender)){
          //printf("routing", "New Parent with same #hops BUT better rssi\n"); 
           updateParent(call AMPacketC.source (msg),hops_to_sink_through_sender, rssi_to_sender);
        }
        else if (call AMPacketC.source(msg) == current_parent){
          //printf("routing", "the parent now has more hops to sink\n"); 
          updateParent(call AMPacketC.source (msg),hops_to_sink_through_sender, rssi_to_sender);
        }
      }
    }
	
    return msg;
  }


	event void AMControl.stopDone(error_t err) {}
}


