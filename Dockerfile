FROM debian:10.4-slim

# Set the timezone for this image
ARG TIMEZONE=UTC

# Install some packages and Steam
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
  echo $TIMEZONE > /etc/timezone && \
  sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list && \
  dpkg --add-architecture i386 && \
  echo "steam steam/purge note" | /usr/bin/debconf-set-selections && \
  echo "steamcmd    steam/license   note" | /usr/bin/debconf-set-selections && \
  echo "steamcmd    steam/question  select I AGREE" | /usr/bin/debconf-set-selections && \
  apt-get update && \
  apt-get install -y steamcmd less net-tools ca-certificates wget curl unzip libsdl2-2.0-0:i386 locales && \
  sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
  locale-gen && \
  rm -rf /var/lib/apt/lists/* && \
  useradd -ms /bin/bash steam && \
  /usr/games/steamcmd +quit

# Select the unprivilegd user (steam)
USER steam
ENV HOME=/home/steam
ENV PATH=/usr/games:$PATH

# Change shell to bash
CMD /bin/bash

# Copy files needed for HLDS installation
RUN mkdir $HOME/hlds
COPY --chown=steam:steam steam/ $HOME/hlds

# Try to install HLDS. This may take some time.
# Steam has this bug that they are not very interested in fixing.
# The workaround is to re-run this routine multiple times until it downloads 100% of the content.
# More info: https://developer.valvesoftware.com/wiki/SteamCMD#Linux
# Workaround: https://danielgibbs.co.uk/2013/11/hlds-steamcmd-workaround-appid-90/
RUN while test "$status" != "Success! App '90' fully installed."; do \
  status=$(/usr/games/steamcmd +login anonymous \
  +force_install_dir $HOME/hlds +app_update 90 validate +quit | \
  tail -1); \
done

# Set our workdir
WORKDIR $HOME/hlds

# Avoid some warning messages due the lack of this file in the right path
RUN mkdir -p $HOME/.steam/sdk32/ && \
  ln -s $HOME/hlds/steamclient.so $HOME/.steam/sdk32/steamclient.so

# Install BasePack
RUN curl -SL https://github.com/AMXX-pl/BasePack/releases/download/1.1.2/base_pack.zip -o base_pack.zip && \
  unzip -o base_pack.zip && \
  rm base_pack.zip && \
  chmod +x ./hlds_linux && \
  chown -R steam:steam /home/steam/hlds

# Copy all additional files from local cstrike directory
COPY --chown=steam:steam cstrike $HOME/hlds/cstrike

# Enable Unprecacher module
RUN echo '' >> $HOME/hlds/cstrike/addons/metamod/plugins.ini && \
  echo 'linux addons/unprecacher/unprecacher_mm_i386.so' >> $HOME/hlds/cstrike/addons/metamod/plugins.ini

# Compile plugins
RUN cd $HOME/hlds/cstrike/addons/amxmodx/scripting && \
    chmod +x compile.sh amxxpc && \
    ./compile.sh && \
    cp -f compiled/* ../plugins/ && \
    cd $HOME/hlds

# Expose ports
EXPOSE 27015/tcp 27015/udp 26900/udp 27020/udp

# Runtime settings
ENV RCON_PASSWORD=""
ENV SV_PASSWORD=""
ENV MAX_PLAYERS="32"
ENV HOST_NAME="Development"
ENV MAP_NAME="de_dust2"
ENV START_OPTIONS="+sv_lan 1 -debug"

# Default run command
ENTRYPOINT ./hlds_run -game cstrike +ip 0.0.0.0 +map "$MAP_NAME" +hostname "$HOST_NAME" \
  +maxplayers $MAX_PLAYERS +rcon_password "$RCON_PASSWORD" +sv_password "$SV_PASSWORD" "$START_OPTIONS"