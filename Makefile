# CHICK makefile

CSC ?= csc
CSCFLAGS ?= -O3 -lfa2
CSI ?= csi

TARGET = CHICK
all: $(TARGET)

# broken?
%.o: %.scm
	$(CSC) $(CSCFLAGS)	-c $^

$(TARGET): chick.scm
	$(CSC) $(CSCFLAGS)	-o $@	$^

interp: chick.scm
	$(CSI) -s $^
run: $(TARGET)
	./$(TARGET)
.PHONY: interp run

# Cleanup
clean:
	rm -f $(TARGET)
