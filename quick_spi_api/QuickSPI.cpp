#include "QuickSPI.h"
#include <cstring>
#include "xil_exception.h"

#define QUICK_SPI_BASE_ADDRESS 0x43C30000
#define INTERRUPT_CONTROLLER_DEVICE_ID XPAR_SCUGIC_SINGLE_DEVICE_ID
#define QUICK_SPI_INTERRUPT_ID XPAR_FABRIC_QUICK_SPI_0_INTERRUPT_INTR

QuickSPI::QuickSPI():
	CPOL(0),
	CPHA(0),
	burst(false),
	read(false),
	slave(0),
	clockDivider(1),
	incomingElementSize(0),
	outgoingElementSize(0),
	numIncomingElements(0),
	numOutgoingElements(0),
	numReadExtraToggles(0),
	numWriteExtraToggles(0),
	memory{},
	numWrittenBits(0),
	numReadBits(0){}

QuickSPI::~QuickSPI(){}

void QuickSPI::setInterruptHandler(void(*interruptHandler)(void*))
{
	GICconfig = XScuGic_LookupConfig(INTERRUPT_CONTROLLER_DEVICE_ID);
	XScuGic_CfgInitialize(&interruptController, GICconfig, GICconfig->CpuBaseAddress);
    XScuGic_SetPriorityTriggerType(&interruptController, QUICK_SPI_INTERRUPT_ID, 0xA0, 0x3);
    XScuGic_Connect(
    		&interruptController,
			QUICK_SPI_INTERRUPT_ID,
			(Xil_InterruptHandler)interruptHandler,
			this);

	/*XScuGic_SelfTest(&interruptController);*/
    Xil_ExceptionRegisterHandler(
    		XIL_EXCEPTION_ID_IRQ_INT,
			(Xil_ExceptionHandler)XScuGic_InterruptHandler,
			&interruptController);

	Xil_ExceptionEnable();
	XScuGic_Enable(&interruptController, QUICK_SPI_INTERRUPT_ID);
}

void QuickSPI::copyBits(size_t numBits, const void* source, void* destination, size_t sourceStartBit, size_t destinationStartBit)
{
	unsigned char* currentWriteByte = static_cast<unsigned char*>(destination);
	const unsigned char* currentReadByte = static_cast<const unsigned char*>(source);

	size_t currentReadBit = sourceStartBit;
	size_t currentWriteBit = computeBitRemainder(destinationStartBit);

	for (size_t i = 0; i < numBits; ++i)
	{
		if (currentReadBit == 8)
		{
			currentReadBit = 0;
			++currentReadByte;
		}

		if (currentWriteBit == 8)
		{
			currentWriteBit = 0;
			++currentWriteByte;
		}

		const unsigned char readMask = 1 << currentReadBit;
		const unsigned char writeMask = 1 << currentWriteBit;

		if (*currentReadByte & readMask)
			*currentWriteByte |= writeMask;
		else
			*currentWriteByte &= ~writeMask;

		++currentReadBit;
		++currentWriteBit;
	}
}

void QuickSPI::readBits(size_t numBits, void* buffer, size_t startBit)
{
	copyBits(
			numBits,
			getReadBuffer() + computeNumBytesIncludingBitRemainder(numReadBits),
			buffer,
			startBit,
			computeBitRemainder(numReadBits));

	numReadBits += numBits;
}

void QuickSPI::writeBits(size_t numBits, const void* buffer, size_t startBit)
{
	copyBits(
			numBits,
			buffer,
			getWriteBuffer() + computeNumBytesIncludingBitRemainder(numWrittenBits),
			startBit,
			computeBitRemainder(numWrittenBits));

	numWrittenBits += numBits;
}

void QuickSPI::updateControl()
{
	unsigned char& firstByte = memory[0];

	CPOL ? firstByte |= 0x1 : firstByte &= 0xfe;
	CPHA ? firstByte |= 0x2 : firstByte &= 0xfd;

	firstByte |= 0x4; /* start */

	burst ? firstByte |= 0x8 : firstByte &= 0xf7;
	read ? firstByte |= 0x10 : firstByte &= 0xef;

	memory[1] = slave;
	memory[2] = clockDivider;
	memory[3] = 0;

	*reinterpret_cast<unsigned short*>(&memory[4]) = outgoingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[6]) = numOutgoingElements;
	*reinterpret_cast<unsigned short*>(&memory[8]) = incomingElementSize;
	*reinterpret_cast<unsigned short*>(&memory[10]) = numWriteExtraToggles;
	*reinterpret_cast<unsigned short*>(&memory[12]) = numReadExtraToggles;
}

void QuickSPI::startTransaction()
{
	u32* address = reinterpret_cast<u32*>(QUICK_SPI_BASE_ADDRESS);
	updateControl();

	memcpy(address, memory, getReadBufferStart());

	numWrittenBits = 0;
	numReadBits = 0;
}

