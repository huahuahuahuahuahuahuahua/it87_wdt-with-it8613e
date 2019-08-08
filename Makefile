TARGET	:= it8786_wdt
KVER	:= $(shell uname -r)
KDIR	:= /lib/modules/$(KVER)/build
PWD	:= $(shell pwd)

obj-m += it8786_wdt.o

all: modules

modules:
	@echo "Making modules $(TARGET).ko ..."
	$(MAKE) -C $(KDIR) M=$(PWD) modules

install: all
	mkdir -v -p "$(DESTDIR)/lib/modules/$(KVER)/kernel/drivers/watchdog"
	install $(TARGET).ko $(DESTDIR)/lib/modules/$(KVER)/kernel/drivers/watchdog/

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

