# Stage 1: Download map data using a modern lightweight image
FROM alpine:latest AS downloader
WORKDIR /data
RUN apk add --no-cache wget
RUN wget https://download.geofabrik.de/asia/iraq-latest.osm.pbf

# Stage 2: Build and run OSRM using the official backend
FROM osrm/osrm-backend:latest
WORKDIR /data

# Copy the pre-downloaded map data from Stage 1
COPY --from=downloader /data/iraq-latest.osm.pbf /data/iraq-latest.osm.pbf

# Process routing data
RUN osrm-extract -p /profile/car.lua /data/iraq-latest.osm.pbf
RUN osrm-partition /data/iraq-latest.osrm
RUN osrm-customize /data/iraq-latest.osrm

# Hugging Face Spaces uses port 7860 by default
EXPOSE 7860

# Start OSRM routing server
CMD ["osrm-routed", "--algorithm", "mld", "--port", "7860", "/data/iraq-latest.osrm"]
