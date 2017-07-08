#include "QuickSPI.h"

QuickSPI::QuickSPI():
	CPOL(0),
	CPHA(0),
	burst(false),
	read(false),
	slave(0),
	incomingElementSize(0),
	outgoingElementSize(0),
	numIncomingElements(0),
	numOutgoingElements(0),
	numReadExtraToggles(0),
	numWriteExtraToggles(0){}

QuickSPI::~QuickSPI(){}

void QuickSPI::updateControl()
{
	memory[1] = slave;
	*reinterpret_cast<unsigned short*>(&memory[2]) = outgoingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[4]) = numOutgoingElements;
	*reinterpret_cast<unsigned short*>(&memory[6]) = incomingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[8]) = numWriteExtraToggles;
	*reinterpret_cast<unsigned short*>(&memory[10]) = numReadExtraToggles;
}

void QuickSPI::write()
{
	updateControl();
}
