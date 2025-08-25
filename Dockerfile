# 1. 기본 이미지 설정
ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

# 2. 필수 패키지 설치
RUN apt-get update -y > /dev/null && \
    apt-get install -y \
        xinetd \
        gcc-multilib \
    > /dev/null

# 3. 사용자 생성
ARG SERVICE_USER=ctf
RUN useradd -ms /bin/bash ${SERVICE_USER}

# 4. 플래그 파일 설정
RUN echo "NT{0verWR1te_rETuRn_aDdreSs}" > /home/${SERVICE_USER}/flag.txt && \
    chown ${SERVICE_USER}:${SERVICE_USER} /home/${SERVICE_USER}/flag.txt && \
    chmod 400 /home/${SERVICE_USER}/flag.txt

# 5. 앱 디렉토리 설정 및 바이너리 복사
ARG APP_BINARY_NAME=return_to_overwrite
ARG APP_DIR_CONTAINER=/home/${SERVICE_USER}/app

RUN mkdir -p ${APP_DIR_CONTAINER}
COPY ./return_to_overwrite ${APP_DIR_CONTAINER}/

# 6. 실행 스크립트 생성
ARG TIMEOUT_SECONDS=300
RUN echo "#!/bin/bash" > /home/${SERVICE_USER}/run.sh && \
    echo "exec timeout ${TIMEOUT_SECONDS} ${APP_DIR_CONTAINER}/${APP_BINARY_NAME}" >> /home/${SERVICE_USER}/run.sh && \
    chmod +x /home/${SERVICE_USER}/run.sh

# 7. 권한 설정
RUN chown -R root:${SERVICE_USER} /home/${SERVICE_USER} && \
    chmod -R 750 /home/${SERVICE_USER} && \
    chmod 550 /home/${SERVICE_USER}/run.sh && \
    chmod 550 ${APP_DIR_CONTAINER}/${APP_BINARY_NAME} && \
    chown ${SERVICE_USER}:${SERVICE_USER} /home/${SERVICE_USER}/flag.txt && \
    chmod 400 /home/${SERVICE_USER}/flag.txt

# 8. xinetd 서비스 설정
ARG XINETD_SERVICE_NAME=pwn_ret2_overwrite
ARG XINETD_PORT=1007
RUN echo "service ${XINETD_SERVICE_NAME}" > /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "{" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    disable     = no" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    flags       = REUSE" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    socket_type = stream" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    protocol    = tcp" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    user        = ${SERVICE_USER}" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    wait        = no" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    server      = /home/${SERVICE_USER}/run.sh" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    type        = UNLISTED" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "    port        = ${XINETD_PORT}" >> /etc/xinetd.d/${XINETD_SERVICE_NAME} && \
    echo "}" >> /etc/xinetd.d/${XINETD_SERVICE_NAME}

# 9. 컨테이너 시작 시 xinetd 실행
EXPOSE ${XINETD_PORT}
CMD ["/usr/sbin/xinetd", "-dontfork"]