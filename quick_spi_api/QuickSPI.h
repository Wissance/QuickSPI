#ifndef SRC_QUICKSPI_H_
#define SRC_QUICKSPI_H_

class QuickSPI
{
public:
	QuickSPI();
	~QuickSPI();

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

	unsigned char* memory;
};

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

#endif /* SRC_QUICKSPI_H_ */
