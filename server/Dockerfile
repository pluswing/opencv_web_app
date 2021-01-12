FROM python:3.9.1-buster
RUN apt update && apt install -y libgl1-mesa-dev
COPY ./requirements.txt /requirements.txt
RUN pip install -r /requirements.txt && \
    rm /requirements.txt
