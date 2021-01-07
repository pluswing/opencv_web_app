start:
	FLASK_APP=app.py flask run -h 0.0.0.0

lint:
	autopep8 -i *.py
	flake8 *.py
	mypy --strict *.py

.PHONY: lint start
