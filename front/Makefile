build-dev:
	elm make src/FileUpload.elm --output=dist/index.html

build:
	mv src/Env.elm src/Env.elm.dev
	cp env/Env.production.elm src/Env.elm
	elm make src/FileUpload.elm --output=dist/index.html
	rm src/Env.elm
	mv src/Env.elm.dev src/Env.elm

test:
	npx elm-test

lint:
	npx elm-format src/ --yes

.PHONY: build-dev build test lint
