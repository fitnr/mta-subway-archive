shell = bash

PYTHON = python

PGUSER ?= $(USER)
PGDATABASE ?= $(PGUSER)
PSQLFLAGS = $(PGDATABASE)
PSQL = psql $(PSQLFLAGS)

export PGDATABASE PGUSER

hours = 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23
DATE = 2001-01-01
year = $(shell echo $(DATE) | sed 's/\(.\{4\}\)-.*/\1/')
month =	$(shell echo $(DATE) | sed 's/.\{4\}-\(.\{2\}\)-.*/\1/')
day =	$(shell echo $(DATE) | sed 's/.\{4\}-.\{2\}-\(.\{2\}\)/\1/')

PB2 = src/gtfs_realtime_pb2.py src/nyct_subway_pb2

ARCHIVE_URL = https://2m9ldwhcmh.execute-api.us-east-2.amazonaws.com/gtfs_rt/historic.mta

# https://groups.google.com/forum/#!searchin/mtadeveloperresources/archive%7Csort:date/mtadeveloperresources/aQqS_f9oYSY/Ps_yIX5FCQAJ
# https://2m9ldwhcmh.execute-api.us-east-2.amazonaws.com/gtfs_rt/historic.mta/{feed}/{year}/{month}/{day}/{archive}
# where {archive} = {feed}-{year}-{month}-{day}-{hour}.tar.bz2
# and feed = feed{n}, where n is one of 1, 26, 16, 21, 2, 11, 31, 36, 51

FEED = 26

.PHONY: all psql psql-% init install clean-date

all:

hour-tars = $(foreach h,$(hours),data/$(year)/$(month)/$(day)/feed$(FEED)-$(DATE)-$(h).tar.bz2)

load: $(foreach h,$(hours),load-$h)

$(foreach h,$(hours),load-$h): load-%: data/$(year)/$(month)/$(day)/feed$(FEED)-$(DATE)-%.tar.bz2
	@mkdir -p $(<D)/$*
	-tar xf $< --keep-newer-files -C $(<D)/$* 2>/dev/null
	parallel $(PYTHON) src/gtfsrtdb.py ::: $(<D)/$*/feed$(FEED)-$(DATE)-$*-*
	@rm -f $(<D)/$*/feed$(FEED)-$(DATE)-$*-*

download: $(hour-tars)

$(hour-tars): data/$(year)/$(month)/$(day)/feed$(FEED)-$(DATE)-%.tar.bz2: | data/$(year)/$(month)/$(day)
	curl -sL -o $@ $(ARCHIVE_URL)/feed$(FEED)/$(year)/$(month)/$(day)/$(@F)

data/$(year)/$(month)/$(day):
	mkdir -p $@

init: sql/schema.sql $(PB2)
	$(PSQL) -f $<

create:
	createuser -s $(PGUSER)
	-createdb $(PGDATABASE)

install: requirements.txt
	$(PYTHON) -m pip install --upgrade --requirement $<

.SECONDEXPANSION:
src/nyct_subway_pb2.py src/gtfs_realtime_pb2.py: src/%_pb2.py: src/$$(subst _,-,$$*).proto
	protoc $< -I$(<D) --python_out=$(@D)
