FROM debian:trixie-slim AS downloader
RUN apt-get update && apt-get install -y wget ca-certificates
RUN wget -O /chrome-remote-desktop.deb https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    wget -O /google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb



FROM debian:trixie-slim

# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=crduser

# use 6 digits at least
ENV PIN=123456
ENV CODE=4/xxx
ENV HOSTNAME=myvirtualdesktoip
ENV USER=crduser
ENV DEBIAN_FRONTEND=noninteractive

# COPY FROM DOWNLOADER
COPY --from=downloader /chrome-remote-desktop.deb /tmp/
COPY --from=downloader /google-chrome.deb /tmp/

# COPY ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh

# DISABLE LANGUAGE CACHE
RUN echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99nolanguages

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP 
RUN apt-get update \
     && apt-get install -y --fix-broken --no-install-recommends --no-install-suggests sudo pulseaudio vim psmisc openbox obconf tint2 xterm fonts-wqy-zenhei fonts-liberation pavucontrol dbus-x11 libutempter0 \
     && apt-get install -y --no-install-recommends --no-install-suggests /tmp/chrome-remote-desktop.deb \
     && apt-get install -y --no-install-recommends --no-install-suggests /tmp/google-chrome.deb \
     && sed -i 's#/usr/bin/google-chrome-stable#/usr/bin/google-chrome-stable --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer#g' /usr/share/applications/google-chrome.desktop \
     && rm -rf /tmp/*.deb \
     && rm -rf /var/lib/apt/lists/* \
     && apt-get clean \
     && apt-get autoclean \
     && rm -rf /usr/share/doc/* /usr/share/man/* /tmp/* \
     && chmod 777 /entrypoint.sh \
     && adduser --disabled-password --gecos '' $USER \
     && adduser $USER sudo \
     && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
     && usermod -aG chrome-remote-desktop $USER 

USER $USER
WORKDIR /home/$USER
RUN  mkdir -p .config/chrome-remote-desktop .config/chrome-remote-desktop/crashpad \
     && chmod a+rx .config/chrome-remote-desktop \
     && echo 'pulseaudio --daemonize=yes --system=false --exit-idle-time=-1 --log-target=stderr'  > .chrome-remote-desktop-session \
     && echo 'pactl load-module module-pipe-sink sink_name=chrome_remote_desktop_session format=s16le rate=48000 channels=2' >> .chrome-remote-desktop-session \
     && echo 'pactl set-default-sink chrome_remote_desktop_session' >> .chrome-remote-desktop-session \
     && echo 'exec openbox-session' >> .chrome-remote-desktop-session \
     && chown -R $USER:$USER /home/$USER

ENTRYPOINT ["/entrypoint.sh"]

