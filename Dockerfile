FROM maven:3.9.5-eclipse-temurin-21 AS build 🛠️
WORKDIR /app

COPY verifier-application/pom.xml verifier-application/
COPY verifier-application/src/ verifier-application/src/

RUN mvn -f verifier-application/pom.xml clean package -DskipTests



ARG SOURCE_IMAGE=eclipse-temurin:21-jre-ubi9-minimal
FROM ${SOURCE_IMAGE}

USER 0

EXPOSE 8080

COPY scripts/entrypoint.sh /app/

ARG JAR_FILE=verifier-application/target/*.jar
COPY ${JAR_FILE} /app/app.jar

RUN set -uxe && \
    chmod g=u /app/entrypoint.sh &&\
    chmod +x /app/entrypoint.sh

WORKDIR /app

USER 1001

ENTRYPOINT ["/app/entrypoint.sh","app.jar"]
