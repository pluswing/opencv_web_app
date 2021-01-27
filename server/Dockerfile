FROM python:3.9.1-buster
RUN apt update && apt install -y libgl1-mesa-dev
COPY . /server
WORKDIR /server
RUN pip install -r /requirements.txt
# TODO gunicornを使う。
ENTRYPOINT make start
