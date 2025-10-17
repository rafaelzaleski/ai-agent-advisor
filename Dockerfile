FROM elixir:1.18.4-otp-28-alpine

# Set environment variables
ENV MIX_ENV=dev \
    LANG=C.UTF-8

# Install necessary OS packages. inotify-tools is for live-reloading.
RUN apk add --no-cache inotify-tools git build-base

# Install the Hex package manager and the Phoenix project generator
RUN mix local.hex --force && \
    mix archive.install hex phx_new --force

# Create the application directory inside the container
WORKDIR /app

# Copy over the dependency files
COPY mix.exs mix.lock ./

RUN mix deps.get

COPY . .

# Expose the port Phoenix runs on
EXPOSE 4000

CMD ["mix", "phx.server"]