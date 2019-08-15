# moxa-it87-wdt-driver

## Moxa IT87 Watchdog driver
the watchdog driver based on
https://elixir.bootlin.com/linux/v4.9.168/source/drivers/watchdog/it87_wdt.c

### Compile & install the driver

#### Install build-essential packages
```
sudo apt-get install build-essential
```

#### Compile the driver
```
make
```

#### Compile and install the driver
```
make install
```

#### Load the watchdog driver
```
modprobe it8786_wdt
```
