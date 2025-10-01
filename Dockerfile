# Use a slim base image with Java 11 JRE for a smaller footprint
FROM eclipse-temurin:11-jre-alpine

# Set a working directory inside the container
WORKDIR /app

# Copy the built .jar file from the 'target' directory into the container
# The result of the 'mvn install' step is this .jar file
COPY target/my-app-0.0.1-SNAPSHOT.jar app.jar

# Expose the port that Spring Boot runs on
EXPOSE 8080

# The command to run when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]
