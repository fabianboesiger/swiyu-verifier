# ==========================================================
# STAGE 1: BUILD - Using direct download to install Maven
# ==========================================================
FROM eclipse-temurin:21-jdk-jammy AS build 🛠️

# Define Maven version as a build argument
ARG MAVEN_VERSION=3.9.5
ARG MAVEN_HOME=/usr/share/maven

# Install necessary tools (curl, unzip) and download Maven binary
USER 0 # Temporarily switch to root
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip && \
    # 1. Download Maven
    curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.zip -o /tmp/maven.zip && \
    # 2. Unzip and place it in MAVEN_HOME
    unzip /tmp/maven.zip -d /usr/share && \
    mv /usr/share/apache-maven-$MAVEN_VERSION $MAVEN_HOME && \
    # 3. Clean up and set PATH
    rm /tmp/maven.zip && \
    ln -s $MAVEN_HOME/bin/mvn /usr/bin/mvn && \
    # 4. Cleanup apt lists
    rm -rf /var/lib/apt/lists/*
    
# Switch back to non-root user (ID 1000 is default for Temurin)
USER 1000 

# Set the working directory
WORKDIR /app

# Copy the application source code
COPY verifier-application/ /app/verifier-application/

# Run the build command
# The -f flag specifies the location of the pom.xml
RUN mvn -f /app/verifier-application/pom.xml clean package -DskipTests

# ==========================================================
# STAGE 2: RUNTIME - Minimal JRE image
# ==========================================================
# This stage remains the same as it was not the source of the policy violation.
FROM eclipse-temurin:21-jre-jammy AS runtime 

# ... (Rest of your runtime stage instructions) ...
EXPOSE 8080
WORKDIR /app
COPY --from=build /app/verifier-application/target/*.jar /app/app.jar
COPY scripts/entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh
USER 1000
ENTRYPOINT ["/app/entrypoint.sh", "app.jar"]
