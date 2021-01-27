start:
	FLASK_APP=src/app.py FLASK_ENV=development flask run -h 0.0.0.0

lint:
	autopep8 -i src/*.py tests/*.py
	flake8 src/*.py tests/*.py
	mypy src/*.py tests/*.py

test:
	PYTHONPATH=. pytest tests

.PHONY: lint start test
