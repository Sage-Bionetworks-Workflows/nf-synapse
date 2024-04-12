FROM ubuntu:22.04

WORKDIR /root

RUN apt-get update
RUN apt-get install -y \
	curl \
	unzip
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
