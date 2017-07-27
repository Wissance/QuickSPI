#ifndef SRC_QUICKSPI_H_
#define SRC_QUICKSPI_H_

#include <cmath>
#include "xscugic.h"

const size_t MEMORY_SIZE = 64;
const size_t CONTROL_SIZE = 14;

class QuickSPI
{
public:
	QuickSPI();
	~QuickSPI();

	static size_t getControlSize();
	static size_t getBufferSize();
	static size_t getWriteBufferStart();
	static size_t getWriteBufferEnd();
	static size_t getReadBufferStart();
	static size_t getReadBufferEnd();

	void* getMemory();
	void* getWriteBuffer();
	void* getReadBuffer();

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

	unsigned char getDivider() const;
	void setDivider(unsigned char pmDivider);

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

	void* getBaseAddress() const;
	void setBaseAddress(void* pmBaseAddress);

	static size_t computeNumBytesIncludingBitRemainder(size_t numBits);
	static size_t computeNumBytesExcludingBitRemainder(size_t numBits);
	static size_t computeBitRemainder(size_t numBits);

	static void copyBits(
			size_t numBits,
			const void* source,
			void* destination,
			size_t sourceStartBit,
			size_t destinationStartBit);

	void readBits(size_t numBits, void* buffer, size_t startBit);
	void writeBits(size_t numBits, const void* buffer, size_t startBit);

	static void reverseByteOrder(size_t numBytes, const void* source, void* destination);
	static void reverseBitOrder(
			size_t numBits,
			const void* source,
			void* destination,
			size_t sourceStartBit,
			size_t destinationStartBit);

	size_t computeNumIncomingBytes() const;
	size_t computeNumOutgoingBytes() const;

	void startTransaction();
	void syncMemory();
private:
	void configureInterruptController();
	void updateControl();

	unsigned char CPOL;
	unsigned char CPHA;
	bool burst;
	bool read;
	unsigned char slave;
	unsigned char numClocksToSkip;
	unsigned short incomingElementSize;
	unsigned short outgoingElementSize;
	unsigned short numIncomingElements;
	unsigned short numOutgoingElements;
	unsigned short numReadExtraToggles;
	unsigned short numWriteExtraToggles;
	unsigned char* memory;
	void* baseAddress;
	size_t numWrittenBits;
	size_t numReadBits;
	XScuGic_Config* GICconfig;
	XScuGic interruptController;
};

inline size_t QuickSPI::getControlSize()
{
	return CONTROL_SIZE;
}

inline size_t QuickSPI::getBufferSize()
{
	return (MEMORY_SIZE - getWriteBufferStart()) / 2;
}

inline size_t QuickSPI::getWriteBufferStart()
{
	return getControlSize();
}

inline size_t QuickSPI::getWriteBufferEnd()
{
	return getWriteBufferStart() + (getBufferSize() - 1);
}

inline size_t QuickSPI::getReadBufferStart()
{
	return getWriteBufferStart() + getBufferSize();
}

inline size_t QuickSPI::getReadBufferEnd()
{
	return getReadBufferStart() + (getBufferSize() - 1);
}

inline void* QuickSPI::getMemory()
{
	return memory;
}

inline void* QuickSPI::getWriteBuffer()
{
	return &memory[getWriteBufferStart()];
}

inline void* QuickSPI::getReadBuffer()
{
	return &memory[getReadBufferStart()];
}

inline void* QuickSPI::getBaseAddress() const
{
	return baseAddress;
}

inline void QuickSPI::setBaseAddress(void* pmBaseAddress)
{
	baseAddress = pmBaseAddress;
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

inline unsigned char QuickSPI::getDivider() const
{
	unsigned char lvDivider = 2;
	unsigned char lvNumClocksToSkip = numClocksToSkip;

	while(lvNumClocksToSkip)
	{
		lvDivider <<= 1;
		--lvNumClocksToSkip;
	}

	return lvDivider;
}

inline void QuickSPI::setDivider(unsigned char pmDivider)
{
	if(pmDivider && !(pmDivider % 2))
	{
		numClocksToSkip = 0;

		unsigned char lvDivider = pmDivider;
		while(lvDivider != 2)
		{
			lvDivider >>= 1;
			++numClocksToSkip;
		}
	}
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

inline size_t QuickSPI::computeNumIncomingBytes() const
{
	return computeNumBytesIncludingBitRemainder(getIncomingElementSize() * getNumIncomingElements());
}

inline size_t QuickSPI::computeNumOutgoingBytes() const
{
	return computeNumBytesIncludingBitRemainder(getOutgoingElementSize() * getNumOutgoingElements());
}

#endif /* SRC_QUICKSPI_H_ */
