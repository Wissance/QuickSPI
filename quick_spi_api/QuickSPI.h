#ifndef SRC_QUICKSPI_H_
#define SRC_QUICKSPI_H_

const size_t MEMORY_SIZE = 256;
const size_t CONTROL_SIZE = 12; /* WRITE_BUFFER_START */

class QuickSPI
{
public:
	QuickSPI();
	~QuickSPI();

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

	void appendUnsignedChar(unsigned char value);
	void appendUnsignedShort(unsigned short value);
	void appendUnsignedInt(unsigned int value);
	void write();

private:
	void updateControl();

	unsigned char CPOL;
	unsigned char CPHA;

	bool burst;
	bool read;
	unsigned char slave;

	unsigned short incomingElementSize;
	unsigned short outgoingElementSize;

	unsigned short numIncomingElements;
	unsigned short numOutgoingElements;

	unsigned short numReadExtraToggles;
	unsigned short numWriteExtraToggles;

	unsigned char memory[MEMORY_SIZE];
	size_t numAppendedBytes;
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

inline void QuickSPI::appendUnsignedChar(unsigned char value)
{
	*reinterpret_cast<unsigned char*>(getWriteBuffer()[numAppendedBytes]) = value;
	++numAppendedBytes;
}

inline void QuickSPI::appendUnsignedShort(unsigned short value)
{
	*reinterpret_cast<unsigned short*>(getWriteBuffer()[numAppendedBytes]) = value;
	numAppendedBytes += 2;
}

inline void QuickSPI::appendUnsignedInt(unsigned int value)
{
	*reinterpret_cast<unsigned int*>(getWriteBuffer()[numAppendedBytes]) = value;
	numAppendedBytes += 4;
}

#endif /* SRC_QUICKSPI_H_ */
