# Use official OpenJDK image
FROM eclipse-temurin:17-jdk

# Set working directory inside container
WORKDIR /app

# Copy your Java source file
COPY Hello.java /app

# Compile the Java file inside the container
RUN javac Hello.java

# Run the program when container starts
CMD ["java", "Hello"]
