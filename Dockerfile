## Stage 1 : build with maven builder image with native capabilities
FROM quay.io/quarkus/ubi-quarkus-native-image:22.2-java17 AS build
# Copy .git folder for jgitver to calculate the version
COPY --chown=quarkus:quarkus .git /code/.git
# Copy maven executables
COPY --chown=quarkus:quarkus mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
COPY --chown=quarkus:quarkus pom.xml /code/
# Copy the modules
COPY --chown=quarkus:quarkus fpi-sms-api-core /code/fpi-sms-api-core
COPY --chown=quarkus:quarkus fpi-sms-api-lib /code/fpi-sms-api-lib
USER quarkus
WORKDIR /code
RUN chmod +x ./mvnw
# Make environment variables accessible for build
ARG GITHUB_USERNAME
ARG GITHUB_TOKEN
# RUN ./mvnw -s ./.mvn/wrapper/settings.xml -B org.apache.maven.plugins:maven-dependency-plugin:3.1.2:go-offline
RUN pwd
RUN ./mvnw --version
RUN ls -alh
RUN ./mvnw -B package -Pnative

## Stage 2 : create the docker final image
FROM quay.io/quarkus/quarkus-micro-image:1.0
WORKDIR /work/
COPY --from=build /code/fpi-sms-api-core/target/*-runner /work/application

# set up permissions for user `1001`
RUN chmod 775 /work /work/application \
  && chown -R 1001 /work \
  && chmod -R "g+rwX" /work \
  && chown -R 1001:root /work

EXPOSE 8080
USER 1001

CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]