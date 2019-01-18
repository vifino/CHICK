# CHICK makefile

CSC ?= csc
CSCFLAGS ?= -O3 -lfa2
CSI ?= csi

TARGET = CHICK
all: $(TARGET)

# broken?
.scm.o:
	$(CSC) $(CSCFLAGS)	-o $@ -c $<

$(TARGET): chick.scm
	$(CSC) $(CSCFLAGS)	-o $@ chick.scm

interp: chick.scm
	$(CSI) -s chick.scm
run: $(TARGET)
	./$(TARGET)
.PHONY: interp run

# Cleanup
clean:
	rm -f $(TARGET)
