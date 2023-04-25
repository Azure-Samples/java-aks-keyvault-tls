FROM mcr.microsoft.com/openjdk/jdk:11-mariner as build

WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN SSL_ENABLED="false" ./mvnw package

FROM mcr.microsoft.com/openjdk/jdk:11-mariner

ARG WAR_FILE=/workspace/app/target/*.jar

COPY --from=build ${WAR_FILE} webapp.war

CMD ["java", "-Dspring.profiles.active=docker", "-jar", "webapp.war"]
