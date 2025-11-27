FROM eclipse-temurin:21-jdk-jammy AS build

# Install Maven manually (using 'apt-get' for Debian/Jammy base)
# Running all commands in one RUN layer minimizes image size.
USER 0 # Temporarily switch to root to install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends maven && \
    rm -rf /var/lib/apt/lists/*
USER 1000 # Switch back to non-root user

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
