FROM timescale/timescaledb:2.31.0-pg18-oss
ARG UNPAIDME_VERSION=1.0.0
ENV POSTGRES_DB=unpaidme
COPY schema/migrations/*.up.sql /docker-entrypoint-initdb.d/
