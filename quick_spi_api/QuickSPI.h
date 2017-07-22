#ifndef SRC_QUICKSPI_H_
#define SRC_QUICKSPI_H_

#include <cmath>
#include "xscugic.h"

const size_t MEMORY_SIZE = 64;
const size_t CONTROL_SIZE = 14; /* WRITE_BUFFER_START */

class QuickSPI
{
public:
	QuickSPI();
	~QuickSPI();

	void setInterruptHandler(void(*handler)(void*));

	size_t getControlSize() const;
	size_t getBufferSize() const;

	size_t getWriteBufferStart() const;
	size_t getWriteBufferEnd() const;

	size_t getReadBufferStart() const;
	size_t getReadBufferEnd() const;

	unsigned char* getMemory();
	unsigned char* getWriteBuffer();
	unsigned char* getReadBuffer();

	unsigned char getCPOL() const;
	void setCPOL(unsigned char pmCPOL);

	unsigned char getCPHA() const;
	void setCPHA(unsigned char pmCPHA);

	bool getBurst() const;
	void setBurst(bool pmBurst);

	bool getRead() const;
	void setRead(bool pmRead);

	unsigned char getSlave() const;
	void setSlave(unsigned char pmSlave);

	unsigned char getClockDivider() const;
	void setClockDivider(unsigned char pmClockDivider);

	unsigned short getIncomingElementSize() const;
	void setIncomingElementSize(unsigned short pmIncomingElementSize);

	unsigned short getOutgoingElementSize() const;
	void setOutgoingElementSize(unsigned short pmOutgoingElementSize);

	unsigned short getNumIncomingElements() const;
	void setNumIncomingElements(unsigned short pmNumIncomingElements);

	unsigned short getNumOutgoingElements() const;
	void setNumOutgoingElements(unsigned short pmNumOutgoingElements);

	unsigned short getNumReadExtraToggles() const;
	void setNumReadExtraToggles(unsigned short pmNumReadExtraToggles);

	unsigned short getNumWriteExtraToggles() const;
	void setNumWriteExtraToggles(unsigned short pmNumWriteExtraToggles);

	static size_t computeNumBytesIncludingBitRemainder(size_t numBits);
	static size_t computeNumBytesExcludingBitRemainder(size_t numBits);
	static size_t computeBitRemainder(size_t numBits);

	static void copyBits(size_t numBits, const void* source, void* destination, size_t sourceStartBit, size_t destinationStartBit);
	void readBits(size_t numBits, void* buffer, size_t startBit);
	void writeBits(size_t numBits, const void* buffer, size_t startBit);

	size_t computeNumOutgoingBytes() const;
	void startTransaction();
private:
	void updateControl();

	unsigned char CPOL;
	unsigned char CPHA;

	bool burst;
	bool read;

	unsigned char slave;
	unsigned char clockDivider;

	unsigned short incomingElementSize;
	unsigned short outgoingElementSize;

	unsigned short numIncomingElements;
	unsigned short numOutgoingElements;

	unsigned short numReadExtraToggles;
	unsigned short numWriteExtraToggles;

	unsigned char memory[MEMORY_SIZE];

	size_t numWrittenBits;
	size_t numReadBits;

	XScuGic_Config* GICconfig;
	XScuGic interruptController;
};

inline size_t QuickSPI::getControlSize() const
{
	return CONTROL_SIZE;
}

inline size_t QuickSPI::getBufferSize() const
{
	return (MEMORY_SIZE - getWriteBufferStart()) / 2;
}

inline size_t QuickSPI::getWriteBufferStart() const
{
	return getControlSize();
}

inline size_t QuickSPI::getWriteBufferEnd() const
{
	return getWriteBufferStart() + (getBufferSize() - 1);
}

inline size_t QuickSPI::getReadBufferStart() const
{
	return getWriteBufferStart() + getBufferSize();
}

inline size_t QuickSPI::getReadBufferEnd() const
{
	return getReadBufferStart() + (getBufferSize() - 1);
}

inline unsigned char* QuickSPI::getMemory()
{
	return memory;
}

inline unsigned char* QuickSPI::getWriteBuffer()
{
	return &memory[getWriteBufferStart()];
}

inline unsigned char* QuickSPI::getReadBuffer()
{
	return &memory[getReadBufferStart()];
}

inline unsigned char QuickSPI::getCPOL() const
{
	return CPOL;
}

inline void QuickSPI::setCPOL(unsigned char pmCPOL)
{
	CPOL = pmCPOL;
}

inline unsigned char QuickSPI::getCPHA() const
{
	return CPHA;
}

inline void QuickSPI::setCPHA(unsigned char pmCPHA)
{
	CPHA = pmCPHA;
}

inline bool QuickSPI::getBurst() const
{
	return burst;
}

inline void QuickSPI::setBurst(bool pmBurst)
{
	burst = pmBurst;
}

inline bool QuickSPI::getRead() const
{
	return read;
}

inline void QuickSPI::setRead(bool pmRead)
{
	read = pmRead;
}

inline unsigned char QuickSPI::getSlave() const
{
	return slave;
}

inline void QuickSPI::setSlave(unsigned char pmSlave)
{
	slave = pmSlave;
}

inline unsigned char QuickSPI::getClockDivider() const
{
	return clockDivider;
}

inline void QuickSPI::setClockDivider(unsigned char pmClockDivider)
{
	clockDivider = pmClockDivider;
}

inline unsigned short QuickSPI::getIncomingElementSize() const
{
	return incomingElementSize;
}

inline void QuickSPI::setIncomingElementSize(unsigned short pmIncomingElementSize)
{
	incomingElementSize = pmIncomingElementSize;
}

inline unsigned short QuickSPI::getOutgoingElementSize() const
{
	return outgoingElementSize;
}

inline void QuickSPI::setOutgoingElementSize(unsigned short pmOutgoingElementSize)
{
	outgoingElementSize = pmOutgoingElementSize;
}

inline unsigned short QuickSPI::getNumIncomingElements() const
{
	return numIncomingElements;
}

inline void QuickSPI::setNumIncomingElements(unsigned short pmNumIncomingElements)
{
	numIncomingElements = pmNumIncomingElements;
}

inline unsigned short QuickSPI::getNumOutgoingElements() const
{
	return numOutgoingElements;
}

inline void QuickSPI::setNumOutgoingElements(unsigned short pmNumOutgoingElements)
{
	numOutgoingElements = pmNumOutgoingElements;
}

inline unsigned short QuickSPI::getNumReadExtraToggles() const
{
	return numReadExtraToggles;
}

inline void QuickSPI::setNumReadExtraToggles(unsigned short pmNumReadExtraToggles)
{
	numReadExtraToggles = pmNumReadExtraToggles;
}

inline unsigned short QuickSPI::getNumWriteExtraToggles() const
{
	return numWriteExtraToggles;
}

inline void QuickSPI::setNumWriteExtraToggles(unsigned short pmNumWriteExtraToggles)
{
	numWriteExtraToggles = pmNumWriteExtraToggles;
}

inline size_t QuickSPI::computeNumBytesIncludingBitRemainder(size_t numBits)
{
	return static_cast<size_t>(ceil(static_cast<double>(numBits) / 8.0));
}

inline size_t QuickSPI::computeNumBytesExcludingBitRemainder(size_t numBits)
{
	return static_cast<size_t>(floor(static_cast<double>(numBits) / 8.0));
}

inline size_t QuickSPI::computeBitRemainder(size_t numBits)
{
	return numBits - (computeNumBytesExcludingBitRemainder(numBits) * 8);
}

inline size_t QuickSPI::computeNumOutgoingBytes() const
{
	return computeNumBytesIncludingBitRemainder(getOutgoingElementSize() * getNumOutgoingElements());
}

#endif /* SRC_QUICKSPI_H_ */
