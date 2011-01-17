
CC=gcc
SRC_LIBEVENT=./libevent-2.0.10-stable
INSTALL_DIR=/home/hotel/work/sys/log-server/
CFLAGS=-pipe  -O -W   -g
LIBS=-lrt $(SRC_LIBEVENT)/.libs/libevent.a \
		$(SRC_LIBEVENT)/.libs/libevent_core.a \
		$(SRC_LIBEVENT)/.libs/libevent_extra.a \
		$(SRC_LIBEVENT)/.libs/libevent_openssl.a \
		$(SRC_LIBEVENT)/.libs/libevent_pthreads.a



log-server: log-server.c
	rm -f log-server
	$(CC)  -I$(SRC_LIBEVENT)/include -o log-server log-server.c $(CFLAGS) $(LIBS)

install: log-server log-server.c
	mkdir -p $(INSTALL_DIR)
	cp -f log-server $(INSTALL_DIR)
	
	
clean: 
	rm -f log-server

