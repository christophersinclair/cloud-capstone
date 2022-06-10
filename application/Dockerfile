FROM python:3.8.13-alpine3.16

ENV AWS_DEFAULT_REGION=''
ENV AWS_ACCESS_KEY_ID=''
ENV AWS_SECRET_ACCESS_KEY=''

RUN mkdir /var/www/
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./requirements.txt /var/www/requirements.txt
COPY ./app.py /var/www/app.py

RUN pip3 install -r /var/www/requirements.txt

EXPOSE 80

CMD "/docker-entrypoint.sh"