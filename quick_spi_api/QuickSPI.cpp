#include "QuickSPI.h"
#include <memory>

namespace
{
	const size_t WRITE_BUFFER_START = 12;
	const size_t BUFFER_SIZE = (MEMORY_SIZE - WRITE_BUFFER_START) / 2;
	const size_t WRITE_BUFFER_END = WRITE_BUFFER_START + (BUFFER_SIZE - 1);
	const size_t READ_BUFFER_START = WRITE_BUFFER_START + BUFFER_SIZE;
	const size_t READ_BUFFER_END = READ_BUFFER_START + (BUFFER_SIZE - 1);
}

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
	memory{} {}

QuickSPI::~QuickSPI(){}

void QuickSPI::updateControl()
{
	CPOL ? memory[0] |= 0x1 : memory[0] &= 0xfe;
	CPHA ? memory[0] |= 0x2 : memory[0] &= 0xfd;

	memory[0] |= 0x4; /* start */

	burst ? memory[0] |= 0x8 : memory[0] &= 0xf7;
	read ? memory[0] |= 0x10: memory[0] &= 0xef;

	memory[1] = slave;
	*reinterpret_cast<unsigned short*>(&memory[2]) = outgoingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[4]) = numOutgoingElements;
	*reinterpret_cast<unsigned short*>(&memory[6]) = incomingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[8]) = numWriteExtraToggles;
	*reinterpret_cast<unsigned short*>(&memory[10]) = numReadExtraToggles;
}

void QuickSPI::write()
{
	void* address;
	updateControl();

	/* Copying control and write buffer. */
	memcpy(address, memory, WRITE_BUFFER_START + BUFFER_SIZE);
}
