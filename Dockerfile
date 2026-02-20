FROM FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP 
RUN apt-get update &&  apt-get install -y curl gpg wget \
     && rm -rf /var/lib/apt/lists/* \
     && apt-get clean \
     && apt-get autoclean

RUN apt-get update \
     && apt-get install -y --fix-broken sudo xvfb vim psmisc dialog openbox obconf tint2 xbase-clients xserver-xorg-video-dummy xterm fonts-noto-cjk pavucontrol dbus-x11 libutempter0 \
     && wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb \
     && apt-get install -y --fix-broken ./chrome-remote-desktop_current_amd64.deb \
     && rm -f chrome-remote-desktop_current_amd64.deb \
     && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
     && apt-get install -y ./google-chrome-stable_current_amd64.deb \
     && sed -i 's#/usr/bin/google-chrome-stable#/usr/bin/google-chrome-stable --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer#g' /usr/share/applications/google-chrome.desktop \
     && rm -rf google-chrome-stable_current_amd64.deb \
     && rm -rf /var/lib/apt/lists/* \
     && apt-get clean \
     && apt-get autoclean

# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=crduser
# use 6 digits at least
ENV PIN=123456
ENV CODE=4/xxx
ENV HOSTNAME=myvirtualdesktoip
ENV USER=crduser

# COPY ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh
RUN  chmod 777 /entrypoint.sh

# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER \
     && mkhomedir_helper $USER \
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

