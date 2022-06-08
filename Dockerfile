FROM python:3.8.13-alpine3.16

ENV AWS_DEFAULT_REGION=''
ENV AWS_ACCESS_KEY_ID=''
ENV AWS_SECRET_ACCESS_KEY=''

RUN pip3 install awscli

CMD aws s3 ls