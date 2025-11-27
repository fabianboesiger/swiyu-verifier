# --------------------
# 1. Build Stage: Compiles Java code and creates the JAR file
# --------------------
# Using the most generic and stable tag for OpenJDK 21 on UBI 9
FROM registry.access.redhat.com/ubi9/openjdk-21 AS build

# Set environment variables for Maven download and installation
ARG MAVEN_VERSION=3.9.5
ARG MAVEN_HOME=/usr/share/maven
ARG PATH="$MAVEN_HOME/bin:$PATH"

USER 0

RUN export MICRODNF_INTERACTIVE=false && \
    # 1. Install only tar and gzip (essential for extraction)
    microdnf install -y tar gzip && \
    set -uxe && \
    # 2. Use the existing curl to download Maven
    curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz -o /tmp/maven.tar.gz && \
    # 3. Extract Maven
    tar -xzf /tmp/maven.tar.gz -C /usr/share/ && \
    mv /usr/share/apache-maven-$MAVEN_VERSION $MAVEN_HOME && \
    # 4. Clean up: Remove tar/gzip
    microdnf remove -y tar gzip && \
    rm /tmp/maven.tar.gz && \
    microdnf clean all

# Set the working directory for the build
WORKDIR /app

# Copy the Maven project files (pom.xml) first
COPY pom.xml .

# Copy both child module directories that the root pom.xml requires.
COPY verifier-application/ verifier-application/
COPY verifier-service/ verifier-service/

# Execute the Maven build
RUN mvn -B -DskipTests package

# --------------------
# 2. Final Stage: Creates the lightweight runtime image
# --------------------
# *** FIX: Using the official Red Hat UBI JRE 21 runtime image ***
FROM registry.access.redhat.com/ubi9/openjdk-21-runtime AS final

# Set a non-root user
USER 0
# Expose the application port
EXPOSE 8080

# Application setup
WORKDIR /app
COPY scripts/entrypoint.sh /app/

# Copy the resulting JAR file from the 'build' stage
COPY --from=build /app/verifier-application/target/*.jar /app/app.jar

# Set permissions
RUN set -uxe && \
    chmod g=u /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Switch to the non-root user for runtime
USER 1001

# Define the command to run the application
ENTRYPOINT ["/app/entrypoint.sh", "app.jar"]
