FROM eclipse-temurin:17-jdk AS builder
WORKDIR /app

FROM eclipse-temurin:17-jre
WORKDIR /app

# Copy the pre-built JAR from Jenkins master workspace to agent
COPY app.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
