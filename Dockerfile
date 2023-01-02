FROM jcrhub.com/docker/ubuntu:20.04

RUN mkdir -p /u01/applications
RUN apt update -y
RUN apt install -y openjdk-11-jdk
RUN apt install -y curl

EXPOSE 8082

WORKDIR /u01/applications
COPY target/urotaxi-1.0.jar .

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl http://localhost:8082/actuator/health || exit 1
ENTRYPOINT [ "java", "-jar", "./urotaxi-1.0.jar" ]
