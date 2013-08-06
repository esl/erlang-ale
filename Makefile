PROJECT=erlang_ale

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
XC_DIR=/usr/local/gcc-4.8.0-for-linux32
ERL_LIB=/usr/local/lib/erlang/lib/erl_interface-3.7.11
CFLAGS=-Wall -I/usr/local/include -I$(ERL_LIB)/include -I$(XC_DIR)/include -Ideps/erlang_portutil -Ideps/pihwm/lib
CC=$(XC_DIR)/bin/i586-pc-linux-gcc
endif

ifeq ($(UNAME), Linux)
ERL_LIB=/usr/lib/erlang/lib/erl_interface-3.7.9
CFLAGS=-Wall -I/usr/local/include -I$(ERL_LIB)/include -Ideps/erlang_portutil -Ideps/pihwm/lib
CC=gcc
endif

#DEPS = edown gen_leader gproc meck pihwm erlang_portutil
DEPS =  gproc meck pihwm erlang_portutil

#dep_edown = https://github.com/esl/edown.git master
#dep_gen_leader = https://github.com/abecciu/gen_leader_revival.git master
dep_gproc = https://github.com/lehoff/gproc.git master
#0.2.13.3
dep_meck = https://github.com/eproxus/meck.git 0.7.2
dep_pihwm = https://github.com/omerk/pihwm.git master "./configure"
dep_erlang_portutil = https://github.com/omerk/erlang_portutil master

include erlang.mk

REBAR_DEPS_DIR=${DEPS_DIR}

ERL_LIBS:=./deps:${ERL_LIBS}

LDFLAGS=-L. -L$(ERL_LIB)/lib -Ldeps/pihwm/lib -Lpriv

# PIHWMLIB = pihwm pi_gpio 

all: init library

library: gpio_port pwm_nif examples

init:
	mkdir -p priv

gpio_port: priv/gpio_port.o deps/erlang_portutil/port_comms.o
	$(CC)  ${LDFLAGS} deps/erlang_portutil/port_comms.o deps/pihwm/lib/pihwm.o deps/pihwm/lib/pi_gpio.o  priv/gpio_port.o -lerl_interface -lei -lpthread -o priv/gpio_port

gpio_test: priv/gpio_test.o
	$(CC) $(LDFLAGS) $< pihwm.o pi_gpio.o -lpthread -o $@

pwm_nif:
	$(CC) $(LDFLAGS) $< -o priv/pwm_nif.so -fpic -shared c_src/pwm_nif.c deps/pihwm/lib/pihwm.c deps/pihwm/lib/pi_pwm.c

examples:
	erlc -o examples examples/*.erl

shell: 
	sudo erl  -sname e1 -setcookie secretcookie -pz deps/*/ebin -pz ebin -pz examples

test:
	ct_run -noshell -pa deps/*/ebin -pa ebin -sname ct -env TEST_DIR test -dir test

run_test:
	ct_run -noshell -pa deps/*/ebin -pa ebin -sname ct -env TEST_DIR test -dir test

clean_ct:
	rm -rf ct_run*
	rm -rf ct_default.css
	rm -rf index.html
	rm -rf all_runs.html
	rm -rf jquery*
	rm -rf variables*@*

priv/%.o: c_src/%.c
	$(CC) -g $(CFLAGS) -c -o $@ $<

.PHONY: all library init shell
