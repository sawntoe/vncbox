FROM golang:1.18 as builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN git clone https://github.com/pgaskin/easy-novnc.git
WORKDIR easy-novnc
RUN go build

WORKDIR /go
RUN git clone https://github.com/yudai/gotty.git
WORKDIR gotty
RUN go mod init && go mod tidy && go mod vendor
RUN go build

FROM debian:12 as final
ARG PACKAGES=""
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install software-properties-common dirmngr apt-transport-https lsb-release ca-certificates
RUN add-apt-repository contrib
RUN apt-get update && apt-get install -y \
    sudo \
    xfce4 \
    xfce4-session \
    xfce4-terminal \
    tightvncserver \
    xterm \
    x11-xserver-utils \
    dbus-x11 \
    mgetty \
    papirus-icon-theme \
    arc-theme 
RUN apt-get remove -y xfce4-power-manager
RUN if ! [[-z "${PACKAGES}"]]; then apt-get install -y ${PACKAGES}; fi
COPY --chmod=0755 --from=builder /go/easy-novnc/easy-novnc /usr/bin
COPY --chmod=0755 --from=builder /go/gotty/gotty /usr/bin

COPY --chmod=0755 skel /etc/skel
RUN useradd -s /bin/bash -m user
RUN groupadd wheel
RUN useradd -s /bin/bash -m -G wheel admin
RUN echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
RUN echo "user ALL = NOPASSWD : /usr/bin/apt-get , /usr/bin/apt" >> /etc/sudoers

RUN mkdir /home/user/.vnc
RUN touch /home/user/.Xresources && echo "Xft.dpi: 96" > /home/user/.Xresources
COPY --chmod=0755 xstartup /home/user/.vnc
RUN chown -R user /home/user/
ENV USER=user
ENV XDG_CONFIG_DIRS=/etc/xdg
COPY --chmod=0755 start /usr/bin

CMD ["/usr/bin/start"]
