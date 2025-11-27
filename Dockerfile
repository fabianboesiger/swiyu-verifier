# --------------------
# 1. Build Stage: Compiles Java code and creates the JAR file
#    Using a full JDK image instead of the standard 'maven' image.
# --------------------
# Start with a full JDK image (same base family as the JRE)
FROM eclipse-temurin:21-jdk-ubi9 AS build

# Set environment variables for Maven download and installation
ARG MAVEN_VERSION=3.9.5
ARG MAVEN_HOME=/usr/share/maven
ARG PATH="$MAVEN_HOME/bin:$PATH"

# Download and install Maven (avoids the official Maven image's internal setup)
RUN set -uxe && \
    # Download Maven distribution
    curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz -o /tmp/maven.tar.gz && \
    # Extract Maven to the target location
    tar -xzf /tmp/maven.tar.gz -C /usr/share/ && \
    # Rename the extracted directory
    mv /usr/share/apache-maven-$MAVEN_VERSION $MAVEN_HOME && \
    # Clean up
    rm /tmp/maven.tar.gz

# Set the working directory for the build
WORKDIR /app

# Copy the Maven project files (pom.xml) first for layer caching
COPY pom.xml .

# Copy the source code
COPY verifier-application/ verifier-application/

# Execute the Maven build to produce the JAR
RUN mvn -B -DskipTests package

# --------------------
# 2. Final Stage: Creates the lightweight runtime image
# --------------------
# Use the minimal JRE image for the final runtime
FROM eclipse-temurin:21-jre-ubi9-minimal

# Set a non-root user (good security practice)
USER 0
# Expose the application port
EXPOSE 8080

# Create the application directory and copy the entrypoint script
WORKDIR /app
COPY scripts/entrypoint.sh /app/

# Copy the resulting JAR file from the 'build' stage
COPY --from=build /app/verifier-application/target/*.jar /app/app.jar

# Set permissions for the entrypoint script
RUN set -uxe && \
    chmod g=u /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Switch to the non-root user for runtime
USER 1001

# Define the command to run the application
ENTRYPOINT ["/app/entrypoint.sh", "app.jar"]
