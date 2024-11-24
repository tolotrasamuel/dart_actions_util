FROM dart:stable

# Set working directory
WORKDIR /app

# Copy the action files
COPY . .

# Install dependencies
RUN dart pub get

# Command to execute the CLI tool
ENTRYPOINT ["dart", "bin/dart_actions_util.dart"]
