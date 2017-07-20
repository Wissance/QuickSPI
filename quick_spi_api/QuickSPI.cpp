#include "QuickSPI.h"
#include <cstring>

#define QUICK_SPI_BASE_ADDRESS 0x43C30000

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
	numWriteExtraToggles(0),
	memory{},
	numAppendedBytes(0){}

QuickSPI::~QuickSPI(){}

void QuickSPI::updateControl()
{
	unsigned char& firstByte = memory[0];

	CPOL ? firstByte |= 0x1 : firstByte &= 0xfe;
	CPHA ? firstByte |= 0x2 : firstByte &= 0xfd;

	firstByte |= 0x4; /* start */

	burst ? firstByte |= 0x8 : firstByte &= 0xf7;
	read ? firstByte |= 0x10: firstByte &= 0xef;

	memory[1] = slave;

	*reinterpret_cast<unsigned short*>(&memory[2]) = outgoingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[4]) = numOutgoingElements;
	*reinterpret_cast<unsigned short*>(&memory[6]) = incomingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[8]) = numWriteExtraToggles;
	*reinterpret_cast<unsigned short*>(&memory[10]) = numReadExtraToggles;
}

void QuickSPI::write()
{
	int* address = reinterpret_cast<int*>(QUICK_SPI_BASE_ADDRESS);
	updateControl();
	memcpy(address, memory, getReadBufferStart());

	numAppendedBytes = 0;
	numReadBytes = 0;
}

/*
Example 1:

	QuickSPI spi;
	spi.setSlave(0);
	spi.setOutgoingElementSize(32);
	spi.setNumOutgoingElements(1);
	*reinterpret_cast<unsigned int*>(spi.getWriteBuffer()) = 0xffffffff;
	spi.write();

Example 2:

	QuickSPI spi;
	spi.setSlave(0);
	spi.setOutgoingElementSize(32);
	spi.setNumOutgoingElements(1);
	spi.appendUnsignedChar(1);
	spi.appendUnsignedChar(2);
	spi.appendUnsignedChar(3);
	spi.write();
*/
