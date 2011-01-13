
CC=gcc
SRC_LIBEVENT=./libevent-2.0.10-stable
CFLAGS=-pipe  -O -W   -g
LIBS=-lrt $(SRC_LIBEVENT)/.libs/libevent.a \
		$(SRC_LIBEVENT)/.libs/libevent_core.a \
		$(SRC_LIBEVENT)/.libs/libevent_extra.a \
		$(SRC_LIBEVENT)/.libs/libevent_openssl.a \
		$(SRC_LIBEVENT)/.libs/libevent_pthreads.a



log-server: log-server.c
	rm -f log-server
	$(CC)  -I$(SRC_LIBEVENT)/include -o log-server log-server.c $(CFLAGS) $(LIBS)
	
	
clean: 
	rm -f log-server

