.PHONY=all build
.DEFUALT=build

LISTS:=$(wildcard lists/*.txt)
QUEUES:=$(wildcard queues/*.txt)
ORDERED:=$(wildcard ordered/*.txt)

MANIFESTS:=$(LISTS:lists/%=boards/%)

BOARDS:=$(MANIFESTS:%.txt=%.html)

THUMBNAILS:=$(BOARDS:%.html=%.webp)

MANIFESTS+=$(QUEUES:queues/%=boards/%)
MANIFESTS+=$(ORDERED:ordered/%=boards/%)

export DATA=data
export THUMBS=thumbs
export SMUT=smut

build: $(BOARDS) $(MANIFESTS) $(THUMBNAILS)
	rsync -rtl "${DATA}/" "griffin.tea-cats.co.uk:/srv/www/tea-cats/${SMUT}/${DATA}/" --delete-delay --progress
	rsync -rtl "${THUMBS}/" "griffin.tea-cats.co.uk:/srv/www/tea-cats/${SMUT}/${THUMBS}/" --delete-delay --progress

all: build unused
	$(MAKE) boards/_all.html

unused: build
	./src/clean-up-dangling-images
	$(MAKE) boards/_unused.html

clean:
	./src/clean-up-dangling-images
	rm -Rf boards/

boards/%.txt: lists/%.txt
	@test -d $(dir $@) || mkdir -vp $(dir $@)
	./src/make-manifest "$^" >$@
	touch -c -m -r "$^" "$@"

boards/%.txt: queues/%.txt
	@test -d $(dir $@) || mkdir -vp $(dir $@)
	./src/make-manifest "$^" >$@
	touch -c -m -r "$^" "$@"

boards/%.txt: ordered/%.txt
	@test -d $(dir $@) || mkdir -vp $(dir $@)
	./src/make-manifest "$^" >$@
	touch -c -m -r "$^" "$@"

boards/%.html: boards/%.txt
	./src/template-board-html "$^" >$@
	ssh griffin.tea-cats.co.uk -- mkdir -p "/srv/www/tea-cats/${SMUT}/$(@:boards/%.html=%)"
	rsync -c "$@" "griffin.tea-cats.co.uk:/srv/www/tea-cats/${SMUT}/$(@:boards/%.html=%)/index.html"

boards/%.webp: boards/%.txt
	./src/make-thumbnail "$^" >$@
	ssh griffin.tea-cats.co.uk -- mkdir -p "/srv/www/tea-cats/${SMUT}/$(@:boards/%.webp=%)"
	rsync -c "$@" "griffin.tea-cats.co.uk:/srv/www/tea-cats/${SMUT}/$(@:boards/%.webp=%)/thumb.webp"

boards/_all.txt: $(MANIFESTS)
	cat $^ >"$@"

boards/_unused.txt: $(MANIFESTS)
	./src/find-unused-images $^ >"$@"
