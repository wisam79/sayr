FROM osrm/osrm-backend:latest

# Install wget to download map data
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /data

# 1. Download Iraq map data from Geofabrik
RUN wget https://download.geofabrik.de/asia/iraq-latest.osm.pbf

# 2. Process routing data for cars (extract, partition, customize)
RUN osrm-extract -p /profile/car.lua /data/iraq-latest.osm.pbf
RUN osrm-partition /data/iraq-latest.osrm
RUN osrm-customize /data/iraq-latest.osrm

# Hugging Face Spaces uses port 7860 by default
EXPOSE 7860

# 3. Start OSRM routing server on port 7860
CMD ["osrm-routed", "--algorithm", "mld", "--port", "7860", "/data/iraq-latest.osrm"]
