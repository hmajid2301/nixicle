FROM alpine:latest

ARG user=dotfiles
ARG group=wheel
ARG uid=1000
ARG dotfiles=dotfiles.git
ARG userspace=hmajid2301.git
ARG vcsprovider=gitlab.com
ARG vcsowner=hmajid2301

USER root

RUN \
	echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
	apk upgrade --no-cache && \
	apk add --update --no-cache \
	sudo \
	autoconf \
	automake \
	libtool \
	nasm \
	ncurses \
	ca-certificates \
	libressl \
	bash-completion \
	cmake \
	ctags \
	file \
	curl \
	build-base \
	gcc \
	coreutils \
	wget \
	neovim \
	git git-doc \
	zsh \
	docker \
	docker-compose

RUN \
	echo "%${group} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
	adduser -D -G ${group} ${user} && \
	addgroup ${user} docker

COPY ./ /home/${user}/.userspace/
RUN \
	git clone --recursive https://${vcsprovider}/${vcsowner}/${dotfiles} /home/${user}/.dotfiles && \
	chown -R ${user}:${group} /home/${user}/.dotfiles && \
	chown -R ${user}:${group} /home/${user}/.userspac

USER ${user}
RUN \
	cd $HOME/.dotfiles && \
	./install-profile devcontainer

ENV XDG_DATA_HOME=/config/.history

CMD []