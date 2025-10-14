FROM curlimages/curl:8.2.1 AS downloader
ARG ARTIFACT_URL
WORKDIR /app
RUN curl -fSL $ARTIFACT_URL -o app.jar

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=downloader /app/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]