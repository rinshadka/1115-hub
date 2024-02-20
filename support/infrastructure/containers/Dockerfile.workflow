# Use Debian 11 (Bullseye) slim as the base image
FROM debian:bullseye-slim
# Avoid prompts from apt during build
ENV DEBIAN_FRONTEND=noninteractive
# Declare REPO_URL as a build-time argument
ARG REPO_URL
# Update packages and install necessary dependencies
RUN apt-get update
RUN apt-get install -y curl unzip wget sqlite3 git cron
RUN rm -rf /var/lib/apt/lists/*

# Install Deno
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
ENV PATH="/root/.deno/bin:$PATH"

# Install DuckDB
RUN wget -qO- https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip >duckdb.zip
RUN unzip duckdb.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/duckdb
RUN export PATH=$PATH:/usr/local/bin
RUN rm duckdb.zip

# Clone the specified GitHub repository
WORKDIR /app
RUN git clone ${REPO_URL}

# Run a Deno script from the cloned repo and store its output in a log file
RUN deno run -A ./1115-hub/support/bin/doctor.ts >doctor_log.txt

# Define system PATH in crontab
RUN echo "PATH=/usr/local/bin:/usr/bin:/bin" >> /etc/cron.d/1115-hub

# create a cron job for each qe1-6 to run the deno script
RUN echo "* * * * * /root/.deno/bin/deno run -A /app/1115-hub/src/ahc-hrsn-elt/screening/orchctl.ts --qe qe1 >> /var/log/qe1.log 2>&1" >> /etc/cron.d/1115-hub && \
    echo "* * * * * /root/.deno/bin/deno run -A /app/1115-hub/src/ahc-hrsn-elt/screening/orchctl.ts --qe qe2 >> /var/log/qe2.log 2>&1" >> /etc/cron.d/1115-hub && \
    echo "* * * * * /root/.deno/bin/deno run -A /app/1115-hub/src/ahc-hrsn-elt/screening/orchctl.ts --qe qe3 >> /var/log/qe3.log 2>&1" >> /etc/cron.d/1115-hub && \
    echo "* * * * * /root/.deno/bin/deno run -A /app/1115-hub/src/ahc-hrsn-elt/screening/orchctl.ts --qe qe4 >> /var/log/qe4.log 2>&1" >> /etc/cron.d/1115-hub && \
    echo "* * * * * /root/.deno/bin/deno run -A /app/1115-hub/src/ahc-hrsn-elt/screening/orchctl.ts --qe qe5 >> /var/log/qe5.log 2>&1" >> /etc/cron.d/1115-hub && \
    echo "* * * * * /root/.deno/bin/deno run -A /app/1115-hub/src/ahc-hrsn-elt/screening/orchctl.ts --qe qe6 >> /var/log/qe6.log 2>&1" >> /etc/cron.d/1115-hub

RUN chmod 0644 /etc/cron.d/1115-hub
RUN crontab /etc/cron.d/1115-hub

# Run the cron job
RUN service cron start

# keep container open with cron
CMD ["cron", "-f"]