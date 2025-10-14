FROM openjdk:17-jdk-slim AS build
WORKDIR /app

ARG ARTIFACT_URL
RUN apt-get update && apt-get install -y wget \
    && wget -O app.jar $ARTIFACT_URL \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


FROM openjdk:17-jre-slim
WORKDIR /app
COPY --from=build /app/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
