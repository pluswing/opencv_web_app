FROM python:3.9.1-buster
RUN apt update && apt install -y libgl1-mesa-dev
COPY . /server
WORKDIR /server
RUN pip install -r requirements.txt
CMD gunicorn -w 4 src.app:app --bind=0.0.0.0:5000
